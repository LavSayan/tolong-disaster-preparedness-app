#!/usr/bin/env python3
"""Extract per-site hazard bands from the bundled NOAH archive for the shelter-ranking model.

`datasets/qc_flood.pmtiles` is a render asset the app never decodes for scoring — decoding
48.7 MB of vector tiles on a phone per ranking call is out of the question. Instead this tool
evaluates every candidate site once, offline, and writes the result as a small JSON table the
app (and the Python trainer) read directly: `tolong_flutter/assets/data/hazard_bands.json`.

Sampling follows `tolong_flutter/docs/design/SHELTER_RANKING_ML.md` §3 exactly:
  - five sample points per site: the centre plus north/east/south/west at 50 m,
  - per source layer, take the **max band across samples** (a site is at most as good as its
    worst sample),
  - per sample, the band comes from the highest zoom level whose tile contains the point,
    falling through to lower zooms when polygons are simplified or a subtile is empty,
  - exposure = max(floodComposite, landslide); floodComposite = 0.5*(L100/3) + 0.3*(L25/3)
    + 0.2*(L5/3); landslide = HAZ/4. Storm surge is landlocked-absent in Quezon City and
    debris flow is deliberately outside the v1 feature — both are reported, never imputed:
    `null` = the layer never shipped data near the site, `0..3|4` = a real band value.

Stdlib only, like every tool under `tools/`. Modes:
  --extract  (re)build `tolong_flutter/assets/data/hazard_bands.json` from the archive (default)
  --check    re-extract in memory and byte-compare against the committed asset; exit 1 on
             drift (archive changed, code changed, or the asset was hand-edited)

Determinism: fixed sample order, sorted JSON keys, no timestamps. Re-running on the same
archive yields a byte-identical file, which is what makes `--check` and the fixture guards
meaningful. Runtime is ~1-2 minutes, dominated by varint decoding of the NOAH polygon rings
(a deliberate one-off cost by design: the app reads the JSON, never the archive).
"""

import argparse
import gzip
import hashlib
import json
import math
import os
import struct
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARCHIVE = os.path.join(REPO_ROOT, "tolong_flutter", "datasets", "qc_flood.pmtiles")
BARANGAYS = os.path.join(REPO_ROOT, "tolong_flutter", "assets", "data", "qc_barangays.json")
CENTERS = os.path.join(REPO_ROOT, "tolong_flutter", "assets", "data", "evacuation_centers_dev.json")
OUT_DEFAULT = os.path.join(REPO_ROOT, "tolong_flutter", "assets", "data", "hazard_bands.json")

HEADER_LEN = 127

# Source layers in the archive (verified by tools/hazard_archive_check) and their severity
# attributes. Flood layers carry `Var` 1..3; everything else carries `HAZ`.
# NOTE: this archive ships NATIONAL NOAH data, not a Quezon City clip — I verified this
# empirically (flood layers alone hold ~1.5M features spanning lat 5.4-20.8) and the parity
# register stays per-point exact because sampling is geodetic PIP against tile polygons.
# The four storm-surge SSA layers are excluded from per-site sampling entirely (see
# site_bands): their simplified low-zoom rings swallow inland Quezon City, so the value
# would be an artifact, and the spec excludes surge from the exposure feature anyway.
FLOOD_LAYERS = ("flood_100yr", "flood_25yr", "flood_5yr")
LANDSLIDE = "landslide"
DEBRIS_FLOW = "debris_flow"
STORM_SURGE_LAYERS = tuple("storm_surge_ssa%d" % i for i in range(1, 5))
ALL_LAYERS = list(FLOOD_LAYERS) + [LANDSLIDE, DEBRIS_FLOW]

SAMPLES = ("center", "north", "east", "south", "west")
SAMPLE_OFFSET_M = 50.0
METERS_PER_DEG_LAT = 111320.0


# --------------------------------------------------------------------------
# Varint / PMTiles / MVT primitives
# --------------------------------------------------------------------------

def read_varint(buf, pos):
    """Single varint read for header/field scanning (small buffers only)."""
    result = shift = 0
    while True:
        byte = buf[pos]
        pos += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, pos
        shift += 7


def unpack_varints(buf):
    """Whole-buffer varint unpacking in one tight loop — this is the decode hot path."""
    out = []
    append = out.append
    value = shift = 0
    for byte in buf:
        value |= (byte & 0x7F) << shift
        if byte < 0x80:
            append(value)
            value = shift = 0
        else:
            shift += 7
    return out


def decompress(data, mode):
    if mode == 1:
        return data
    if mode == 2:
        return gzip.decompress(data)
    raise SystemExit("unsupported PMTiles compression mode %d" % mode)


def parse_directory(buf):
    """PMTiles v3 columnar directory: one varint per entry, four columns after the count:
    id deltas, run lengths, lengths, offsets. (Offset value 0 means "continue after the
    previous entry".) Verified against the known-good tile list of the bundled archive."""
    values = unpack_varints(buf)
    pos = 0
    count = values[pos]; pos += 1
    ids = []
    last = 0
    for _ in range(count):
        last += values[pos]; pos += 1
        ids.append(last)
    run_lengths = []
    for _ in range(count):
        run_lengths.append(values[pos]); pos += 1
    lengths = []
    for _ in range(count):
        lengths.append(values[pos]); pos += 1
    offsets = []
    prev_offset = prev_length = 0
    for index in range(count):
        value = values[pos]; pos += 1
        offsets.append(prev_offset + prev_length if value == 0 and index > 0 else value - 1)
        prev_offset, prev_length = offsets[-1], lengths[index]
    return list(zip(ids, run_lengths, lengths, offsets))


def read_pbf_fields(buf, start=0, end=None):
    end = len(buf) if end is None else end
    pos = start
    while pos < end:
        key, pos = read_varint(buf, pos)
        field, wire = key >> 3, key & 7
        if wire == 0:
            value, pos = read_varint(buf, pos)
            yield field, wire, value
        elif wire == 1:
            value = struct.unpack_from("<q", buf, pos)[0]
            pos += 8
            yield field, wire, value
        elif wire == 2:
            length, pos = read_varint(buf, pos)
            yield field, wire, buf[pos:pos + length]
            pos += length
        elif wire == 5:
            value = struct.unpack_from("<f", buf, pos)[0]
            pos += 4
            yield field, wire, value
        else:
            raise SystemExit("unsupported wire type %d in protobuf" % wire)


def decode_value(buf):
    """One MVT Value message: 1 string, 2/3 float/double, 4/5/6 ints, 7 bool."""
    for field, _, value in read_pbf_fields(buf):
        if field == 1:
            return value.decode("utf-8", "replace")
        if field in (2, 3, 4, 5):
            return value
        if field == 6:
            return (value >> 1) ^ -(value & 1)
        if field == 7:
            return value
    return None


def hilbert_d2xy(z, d):
    """Standard Hilbert curve inverse (Hamilton's implementation) — verified empirically
    against this archive (tiles land exactly on Quezon City at every zoom)."""
    n = 1 << z
    t = d
    x = y = 0
    s = 1
    while s < n:
        rx = 1 & (t // 2)
        ry = 1 & (t ^ rx)
        if ry == 0:
            if rx == 1:
                x = s - 1 - x
                y = s - 1 - y
            x, y = y, x
        x += rx * s
        y += ry * s
        t //= 4
        s *= 2
    return x, y


# --------------------------------------------------------------------------
# Geometry: flat rings [x0, y0, x1, y1, ...] in part units + polygon grouping
# --------------------------------------------------------------------------

def parse_geometry(values):
    """MVT command stream -> flat ring lists [x0, y0, x1, y1, ...], first vertex not repeated.

    Coordinates accumulate across the whole geometry: MoveTo starts a ring (a LineTo-style
    absolute delta from the previous vertex), LineTo continues, ClosePath ends the ring.
    Zeroing the cursor between rings is the classic MVT corruption bug — deltas chain across
    rings inside one geometry.
    """
    rings = []
    current = []
    cx = cy = 0
    index = 0
    total = len(values)
    while index < total:
        cmd = values[index]
        index += 1
        cmd_id, count = cmd & 7, cmd >> 3
        if cmd_id == 1 or cmd_id == 2:  # MoveTo / LineTo
            for _ in range(count):
                dx = values[index]
                dy = values[index + 1]
                index += 2
                cx += (dx >> 1) ^ -(dx & 1)
                cy += (dy >> 1) ^ -(dy & 1)
                current.append(cx)
                current.append(cy)
        elif cmd_id == 7:  # ClosePath: ends the current ring
            if len(current) >= 8:
                rings.append(current)
            current = []
        else:
            raise SystemExit("unknown MVT geometry command %d" % cmd_id)
    if len(current) >= 8:
        # Ring left unclosed by the command stream; most encoders close explicitly.
        rings.append(current)
    return rings


def ring_area(ring):
    """Signed double area of an open ring (closing edge last -> first implied).
    Positive = exterior, negative = hole, under the MVT winding rule."""
    total = 0.0
    pairs = len(ring) // 2
    if pairs < 3:
        return 0.0
    xi = ring[0]
    yi = ring[1]
    for i in range(1, pairs):
        xj = ring[2 * i]
        yj = ring[2 * i + 1]
        total += (xi + xj) * (yj - yi)
        xi, yi = xj, yj
    total += (xi + ring[0]) * (ring[1] - yi)
    return total


def bbox(ring):
    xs = ring[0::2]
    ys = ring[1::2]
    return min(xs), min(ys), max(xs), max(ys)


def point_in_ring(px, py, ring):
    """Even-odd crossing test over a flat open ring (closing edge last -> first implied)."""
    inside = False
    limit = len(ring)
    ax, ay = ring[0], ring[1]
    for i in range(2, limit, 2):
        bx, by = ring[i], ring[i + 1]
        if (ay > py) is not (by > py):
            if px < ax + (py - ay) / (by - ay) * (bx - ax):
                inside = not inside
        ax, ay = bx, by
    bx, by = ring[0], ring[1]
    if (ay > py) is not (by > py):
        if px < ax + (py - ay) / (by - ay) * (bx - ax):
            inside = not inside
    return inside


def polygons_from_rings(rings):
    """MVT winding: exterior rings positive area, holes negative. Multipolygon interleaving:
    each positive ring starts a polygon; negatives attach to the current exterior."""
    polygons = []
    exterior = None
    holes = []
    for ring in rings:
        if len(ring) < 8:
            continue
        area = ring_area(ring)
        if area >= 0:
            if exterior is not None:
                polygons.append((exterior, holes))
            exterior = ring
            holes = []
        else:
            if exterior is None:
                exterior = ring
                holes = []
            else:
                holes.append(ring)
    if exterior is not None:
        polygons.append((exterior, holes))
    return polygons


def point_in_polygons(px, py, polygons):
    for index, (exterior, holes, box) in enumerate(polygons):
        if px < box[0] or px > box[2] or py < box[1] or py > box[3]:
            continue
        if not point_in_ring(px, py, exterior):
            continue
        if any(point_in_ring(px, py, hole) for hole in holes):
            continue
        return True
    return False


# --------------------------------------------------------------------------
# Tile decoding
# --------------------------------------------------------------------------

def decode_tile(mvt):
    """One decompressed MVT -> {layer: [(band, [(exterior, holes, bbox), ...] sorted by band desc)]}."""
    layers = {}
    for field, _, payload in read_pbf_fields(mvt):
        if field != 3:
            continue
        name = None
        keys = []
        values = []
        extent = 4096
        features = []
        for f, _, p in read_pbf_fields(payload):
            if f == 1:
                name = p.decode("utf-8", "replace")
            elif f == 3:
                keys.append(p.decode("utf-8", "replace"))
            elif f == 4:
                values.append(decode_value(p))
            elif f == 5:
                extent = p
            elif f == 2:
                features.append(p)
        bands = {}
        cheapest = "Var" if name in FLOOD_LAYERS else "HAZ"
        for feature in features:
            ftype = None
            geometry = None
            tags = None
            for f, _, p in read_pbf_fields(feature):
                if f == 2:
                    tags = p
                elif f == 3:
                    ftype = p
                elif f == 4:
                    geometry = p
            if ftype != 3 or geometry is None:
                continue
            band = None
            if tags:
                tag_values = unpack_varints(tags)
                for i in range(0, len(tag_values) - 1, 2):
                    if keys[tag_values[i]] == cheapest:
                        raw = values[tag_values[i + 1]]
                        if isinstance(raw, str):
                            try:
                                raw = float(raw)
                            except ValueError:
                                continue
                        if isinstance(raw, (int, float)):
                            band = int(round(raw))
                        break
            if band is None:
                continue
            polys = polygons_from_rings(parse_geometry(unpack_varints(geometry)))
            if polys:
                bands.setdefault(band, []).extend((e, h, bbox(e)) for e, h in polys)
        layer_out = []
        for band in sorted(bands, reverse=True):
            layer_out.append((band, bands[band]))
        layers[name] = (extent, layer_out)
    return layers


def load_archive(path):
    """Decode the archive -> ({(z, x, y): layers}, provenance dict)."""
    with open(path, "rb") as handle:
        raw = handle.read()
    header = raw[:HEADER_LEN]
    if header[:7] != b"PMTiles":
        raise SystemExit("%s does not start with the PMTiles magic" % path)
    u64 = lambda o: struct.unpack_from("<Q", header, o)[0]
    directory = parse_directory(decompress(raw[u64(8):u64(8) + u64(16)], header[97]))
    tile_offset = u64(56)
    tiles = {}
    for tile_id, run_length, length, offset in directory:
        if run_length != 1:
            raise SystemExit("run_length %d entries (leaf directories) are unsupported" % run_length)
        acc, z = 0, 0
        while True:
            ring = (1 << z) * (1 << z)
            if acc + ring > tile_id:
                x, y = hilbert_d2xy(z, tile_id - acc)
                mvt = decompress(raw[tile_offset + offset:tile_offset + offset + length], header[98])
                tiles[(z, x, y)] = decode_tile(mvt)
                break
            acc += ring
            z += 1
    provenance = {
        "sha256": hashlib.sha256(raw).hexdigest(),
        "sizeBytes": len(raw),
        "tiles": len(tiles),
        "zoomRange": [min(z for z, _, _ in tiles), max(z for z, _, _ in tiles)],
        "nationalDataNote": "this archive carries national NOAH extent (millions of polygon "
                            "features spanning the Philippines), despite the repo note saying "
                            "clipped-to-QC; band sampling is point-in-polygon against the real "
                            "geometry so values remain geodetically exact, and sampling stays "
                            "independent of the archive's clip claims.",
    }
    return tiles, provenance


# --------------------------------------------------------------------------
# Band sampling
# --------------------------------------------------------------------------

def sample_points(lat, lng):
    """Center + N/E/S/W at 50 m (spec §3 sampling rule)."""
    lat_offset = SAMPLE_OFFSET_M / METERS_PER_DEG_LAT
    lng_offset = SAMPLE_OFFSET_M / (METERS_PER_DEG_LAT * math.cos(math.radians(lat)))
    return {
        "center": (lat, lng),
        "north": (lat + lat_offset, lng),
        "east": (lat, lng + lng_offset),
        "south": (lat - lat_offset, lng),
        "west": (lat, lng - lng_offset),
    }


def band_at_point(tiles, layer, lat, lng, max_zoom=14):
    """Band of [layer] at (lat, lng), evaluated at the FIRST zoom level (finest first) whose
    tile contains the point and carries the layer. Returns (seen, band).

    One evaluation, at the finest data available for the point — lower zooms carry only
    simplified copies of the same national polygons, and simplified rings can swallow
    neighbouring inland areas, so mixing zooms would fabricate coverage. Band 0 therefore
    means "the finest available data for this point maps no hazard of that layer"; data gaps
    (no tile at any zoom carrying the layer) keep seen=False → null. The archive is national
    NOAH data, so fine tiles exist wherever polygons exist; an all-zooms miss is genuinely
    'no data for this layer here'.
    """
    n_norm = (lng + 180.0) / 360.0
    d_norm = (1.0 - math.asinh(math.tan(math.radians(lat))) / math.pi) / 2.0
    for zoom in range(max_zoom, -1, -1):
        scale = 1 << zoom
        x_tile = int(n_norm * scale)
        y_tile = int(d_norm * scale)
        tile = tiles.get((zoom, x_tile, y_tile))
        if tile is None:
            continue
        layer_data = tile.get(layer)
        if layer_data is None:
            continue
        extent, band_groups = layer_data
        ex = (n_norm * scale - x_tile) * extent
        ey = (d_norm * scale - y_tile) * extent
        best = 0
        for band, groups in band_groups:
            if point_in_polygons(ex, ey, groups):
                if band > best:
                    best = band
                break
        return True, best
    return False, 0


def site_bands(tiles, lat, lng):
    """Per-layer max band across the five samples for one site.

    Storm surge is sampled nowhere: the SSA layers in this archive are national-resolution
    and their simplified rings overlap inland Quezon City at low zooms, so any per-site value
    would be an artifact, and the app's legend already reports surge as coastal-not-QC.
    Per spec §3 storm surge is excluded from the exposure feature and reported once as a
    global note, so the site key stays present as null.
    """
    max_zoom = max(z for z, _, _ in tiles)
    result = {}
    for layer in ALL_LAYERS:
        seen = False
        best = None
        for point in sample_points(lat, lng).values():
            found, band = band_at_point(tiles, layer, point[0], point[1], max_zoom)
            if found:
                seen = True
                if best is None or band > best:
                    best = band
        result[layer] = best if seen else None
    # All four SSA layers are national-resolution here: recorded as null (see module note) —
    # never a per-candidate value that could become a phantom exposure.
    result["storm_surge"] = None
    return result


def flood_fraction(band, scale):
    if band is None:
        # A single absent return period inside present flood data contributes 0; complete
        # absence of all three is handled by the caller (exposure stays None).
        return 0.0
    return band / scale


def exposure_from_bands(bands):
    b100, b25, b5 = bands["flood_100yr"], bands["flood_25yr"], bands["flood_5yr"]
    if all(v is None for v in (b100, b25, b5)):
        flood_composite = None
    else:
        # Spec formula: 0.5*(L100/3) + 0.3*(L25/3) + 0.2*(L5/3)
        flood_composite = (0.5 * flood_fraction(b100, 3)
                           + 0.3 * flood_fraction(b25, 3)
                           + 0.2 * flood_fraction(b5, 3))
    landslide = None if bands[LANDSLIDE] is None else bands[LANDSLIDE] / 4.0
    candidates = [v for v in (flood_composite, landslide) if v is not None]
    exposure = max(candidates) if candidates else None
    basis = []
    if flood_composite is not None:
        basis.append("floodComposite")
    if landslide is not None:
        basis.append("landslide")
    return {
        "floodComposite": round(flood_composite, 9) if flood_composite is not None else None,
        "landslide": round(landslide, 9) if landslide is not None else None,
        "exposure": round(exposure, 9) if exposure is not None else None,
        "basis": basis,
    }


# --------------------------------------------------------------------------
# Site lists and output document
# --------------------------------------------------------------------------

def load_sites():
    sites = []
    with open(BARANGAYS, encoding="utf-8") as handle:
        data = json.load(handle)
    for index, barangay in enumerate(data["barangays"]):
        sites.append({
            "id": "bgy-%03d" % index,
            "kind": "barangay",
            "name": barangay["name"],
            "psgc": barangay["psgc"],
            "lat": barangay["lat"],
            "lng": barangay["lng"],
        })
    with open(CENTERS, encoding="utf-8") as handle:
        data = json.load(handle)
    for center in data["centers"]:
        sites.append({
            "id": center["id"],
            "kind": "demo",
            "name": center["name"],
            "lat": center["lat"],
            "lng": center["lng"],
        })
    return sites


def build_document(tiles, provenance, sites):
    site_entries = []
    band_distribution = {}
    for site in sites:
        bands = site_bands(tiles, site["lat"], site["lng"])
        for layer, band in bands.items():
            key = (layer, "null" if band is None else band)
            band_distribution[key] = band_distribution.get(key, 0) + 1
        site_entries.append({
            "id": site["id"],
            "kind": site["kind"],
            "name": site["name"],
            **({"psgc": site["psgc"]} if "psgc" in site else {}),
            "lat": site["lat"],
            "lng": site["lng"],
            "bands": bands,
            "exposure": exposure_from_bands(bands),
        })

    notes = []
    notes.append("storm_surge: reported once, never per site — the SSA layers in this archive "
                 "are national-resolution and simplified low-zoom rings overlap inland "
                 "Quezon City; per spec §3 storm surge is excluded from the exposure feature "
                 "(landlocked QC), so every site carries storm_surge: null.")
    debris_sites = [s["id"] for s in site_entries if (s["bands"][DEBRIS_FLOW] or 0) > 0]
    if debris_sites:
        notes.append("debris_flow: bands 1+ exist at %d site(s) but are excluded from the v1 "
                     "exposure feature (max(floodComposite, landslide) only), per "
                     "SHELTER_RANKING_ML.md §3." % len(debris_sites))
    national = provenance.get("nationalDataNote")
    if national:
        notes.append(national)

    return {
        "asset": "hazard_bands",
        "version": 1,
        "source": {
            "archive": "tolong_flutter/datasets/qc_flood.pmtiles",
            **provenance,
        },
        "provenance": {
            "extractedBy": "tools/ranking/extract_bands.py --extract",
            "siteLists": [
                "tolong_flutter/assets/data/qc_barangays.json",
                "tolong_flutter/assets/data/evacuation_centers_dev.json",
            ],
            "specReference": "tolong_flutter/docs/design/SHELTER_RANKING_ML.md §3",
        },
        "sampling": {
            "offsetMeters": SAMPLE_OFFSET_M,
            "samples": list(SAMPLES),
            "aggregation": "maxBandAcrossSamples",
            "zoomStrategy": "each sample evaluated once, at the finest zoom whose tile "
                            "contains it and carries the layer; lower zooms are never mixed "
                            "(their simplified rings can swallow neighbouring inland areas)",
            "nullSemantics": "band null = layer never shipped data near the site; band 0 = map "
                             "data exists there and contains no hazard polygon at that point",
        },
        "exposureFormula": {
            "floodComposite": "0.5*(flood_100yr/3) + 0.3*(flood_25yr/3) + 0.2*(flood_5yr/3)",
            "landslide": "landslide/4",
            "exposure": "max(floodComposite, landslide)",
        },
        "notes": sorted(set(notes)),
        "sites": site_entries,
    }


def serialize(document):
    return json.dumps(document, ensure_ascii=False, indent=2, sort_keys=True) + "\n"


def extract(out_path):
    tiles, provenance = load_archive(ARCHIVE)
    document = build_document(tiles, provenance, load_sites())
    payload = serialize(document)
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with open(out_path, "w", encoding="utf-8", newline="\n") as handle:
        handle.write(payload)

    print("wrote %s (%d bytes) — %d sites"
          % (os.path.relpath(out_path, REPO_ROOT).replace("\\", "/"), len(payload), len(document["sites"])))
    for layer in list(FLOOD_LAYERS) + [LANDSLIDE, DEBRIS_FLOW] + ["storm_surge"]:
        counts = {}
        for entry in document["sites"]:
            band = entry["bands"][layer]
            key = "null" if band is None else band
            counts[key] = counts.get(key, 0) + 1
        detail = ", ".join("%s: %d" % (k, counts[k]) for k in sorted(counts, key=str))
        print("  %-13s %s" % (layer, detail))
    exposures = [e["exposure"]["exposure"] for e in document["sites"] if e["exposure"]["exposure"] is not None]
    if exposures:
        print("  exposure: min %.3f max %.3f mean %.3f (n=%d)"
              % (min(exposures), max(exposures), sum(exposures) / len(exposures), len(exposures)))
    for note in document["notes"]:
        print("  note: %s" % note)
    return 0


def check(out_path):
    with open(out_path, encoding="utf-8") as handle:
        committed = handle.read()
    tiles, provenance = load_archive(ARCHIVE)
    document = build_document(tiles, provenance, load_sites())
    if serialize(document) != committed:
        print("hazard_bands.json drift detected; rerun: python tools/ranking/extract_bands.py --extract")
        return 1
    print("OK: hazard_bands.json matches the archive (%d sites)" % len(document["sites"]))
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--extract", action="store_true", help="rebuild the asset from the archive (default)")
    parser.add_argument("--check", action="store_true", help="compare the asset against a fresh extraction")
    parser.add_argument("--out", default=OUT_DEFAULT, help="asset path")
    args = parser.parse_args(argv)
    if args.check:
        return check(args.out)
    return extract(args.out)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
