#!/usr/bin/env python3
"""Record the attribute fields the bundled NOAH hazard archive actually carries.

The overlay's severity filter must compare the codes the tiles really store. `Var`/`HAZ` are
numbers — 1..3 for flood, 1..4 for the HAZ layers — while an earlier filter compared them as
strings, which matched nothing: the legend rendered, the map stayed blank, and no error was
thrown anywhere. This tool decodes the archive directly so the Dart tests can pin the declared
severity bands to the real data instead of hard-coded lists (metadata `tilestats` in the
archive is generated from the national source and is stale, so tiles are the honest source).

Modes:
  --extract  Rebuild test/fixtures/hazard_archive_fields.json from the archive itself
             (every tile decoded; per source layer: attribute, storage type, observed values).
  --check    Re-decode the archive and compare against the committed fixture: identical
             provenance (sha256, size, tile count, zoom range) and identical fields.
             Exits 1 on any drift. This is the default mode.

Stdlib only. Run from anywhere; paths resolve relative to the repository root.
"""

import argparse
import gzip
import hashlib
import io
import json
import os
import struct
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
ARCHIVE = os.path.join(REPO_ROOT, 'tolong_flutter', 'datasets', 'qc_flood.pmtiles')
FIXTURE = os.path.join(REPO_ROOT, 'tolong_flutter', 'test', 'fixtures', 'hazard_archive_fields.json')

HEADER_LEN = 127
COMPRESSION_LABEL = {1: 'none', 2: 'gzip', 3: 'brotli', 4: 'zstd'}
VALUE_KIND_LABEL = {
    'STRING': 'string',
    'FLOAT': 'number',
    'DOUBLE': 'number',
    'INT': 'number',
    'UINT': 'number',
    'SINT': 'number',
    'BOOL': 'boolean',
}


def read_varint(buf, pos):
    result = shift = 0
    while True:
        byte = buf[pos]
        pos += 1
        result |= (byte & 0x7F) << shift
        if not byte & 0x80:
            return result, pos
        shift += 7


def decompress(data, mode):
    if mode == 1:
        return data
    if mode == 2:
        return gzip.decompress(data)
    raise SystemExit('unsupported compression mode %d' % mode)


def parse_directory(buf):
    """PMTiles v3 directories are columnar: id deltas, then run lengths, lengths, offsets."""
    count, pos = read_varint(buf, 0)
    ids = []
    last = 0
    for _ in range(count):
        last += read_varint(buf, pos)[0]
        _, pos = read_varint(buf, pos)
        ids.append(last)
    run_lengths = []
    for _ in range(count):
        run_lengths.append(read_varint(buf, pos)[0])
        _, pos = read_varint(buf, pos)
    lengths = []
    for _ in range(count):
        lengths.append(read_varint(buf, pos)[0])
        _, pos = read_varint(buf, pos)
    offsets = []
    prev_offset = prev_length = 0
    for index in range(count):
        value, pos = read_varint(buf, pos)
        if value == 0 and index > 0:
            offsets.append(prev_offset + prev_length)
        else:
            offsets.append(value - 1)
        prev_offset, prev_length = offsets[-1], lengths[index]
    return list(zip(ids, run_lengths, lengths, offsets))


def read_pbf_fields(buf, start, end=None):
    end = len(buf) if end is None else end
    pos = start
    while pos < end:
        key, pos = read_varint(buf, pos)
        field, wire = key >> 3, key & 7
        if wire == 0:
            value, pos = read_varint(buf, pos)
            yield field, wire, value
        elif wire == 1:
            value = struct.unpack_from('<q', buf, pos)[0]
            pos += 8
            yield field, wire, value
        elif wire == 2:
            length, pos = read_varint(buf, pos)
            yield field, wire, buf[pos:pos + length]
            pos += length
        elif wire == 5:
            value = struct.unpack_from('<f', buf, pos)[0]
            pos += 4
            yield field, wire, value
        else:
            raise SystemExit('unsupported wire type %d in protobuf' % wire)


def decode_value(buf):
    """One MVT Value message: field 1 is string_value, 2/3 float/double, 4/5/6 ints, 7 bool."""
    for field, _, value in read_pbf_fields(buf, 0):
        if field == 1:
            return 'STRING', value.decode('utf-8', 'replace')
        if field in (2, 3):
            return 'FLOAT', value
        if field in (4, 5, 6):
            return 'INT', value
        if field == 7:
            return 'BOOL', value
    raise SystemExit('MVT value with no payload')


def unpack_varints(buf):
    values = []
    pos = 0
    while pos < len(buf):
        values.append(read_varint(buf, pos)[0])
        _, pos = read_varint(buf, pos)
    return values


def scan_archive(archive_path):
    """Decode every tile and collect, per source layer, one attribute with its type and values."""
    raw = open(archive_path, 'rb').read()
    header = raw[:HEADER_LEN]
    if header[:7] != b'PMTiles':
        raise SystemExit('%s does not start with the PMTiles magic' % archive_path)
    u64 = lambda o: struct.unpack_from('<Q', header, o)[0]
    root_offset, root_length = u64(8), u64(16)
    tile_offset = u64(56)
    min_zoom, max_zoom = header[100], header[101]
    num_addressed_tiles = u64(72)
    internal_mode, tile_mode = header[97], header[98]

    directory = parse_directory(decompress(raw[root_offset:root_offset + root_length], internal_mode))
    fields = {}
    for _tile_id, _run_length, length, offset in directory:
        mvt = decompress(raw[tile_offset + offset:tile_offset + offset + length], tile_mode)
        for layer_field, _, layer in read_pbf_fields(mvt, 0):
            if layer_field != 3:
                continue
            name, keys, values = None, [], []
            for f, _, payload in read_pbf_fields(layer, 0):
                if f == 1:
                    name = payload.decode()
                elif f == 3:
                    keys.append(payload.decode())
                elif f == 4:
                    values.append(decode_value(payload))
            if len(keys) != 1:
                raise SystemExit('layer %s carries %d attributes (%s); the overlay expects one'
                                 % (name, len(keys), keys))
            attribute = keys[0]
            record = fields.setdefault(name, {'attribute': attribute, 'values': set(), 'kinds': set()})
            if record['attribute'] != attribute:
                raise SystemExit('layer %s carries different keys across tiles: %s vs %s'
                                 % (name, record['attribute'], attribute))
            for f, _, feature in read_pbf_fields(layer, 0):
                if f != 2:
                    continue
                tag_pairs = []
                for f2, _, payload in read_pbf_fields(feature, 0):
                    if f2 == 2:
                        tag_pairs = unpack_varints(payload)
                for i in range(0, len(tag_pairs), 2):
                    kind, value = values[tag_pairs[i + 1]]
                    record['values'].add(value)
                    record['kinds'].add(kind)
    out = {}
    for name, record in fields.items():
        if len(record['kinds']) != 1:
            raise SystemExit('layer %s mixes value kinds %s' % (name, sorted(record['kinds'])))
        out[name] = {
            'attribute': record['attribute'],
            'type': VALUE_KIND_LABEL[record['kinds'].pop()],
            'values': sorted(record['values']),
        }
    return {
        'sha256': hashlib.sha256(raw).hexdigest(),
        'size_bytes': len(raw),
        'spec_version': header[7],
        'tiles': num_addressed_tiles,
        'zoom_range': [min_zoom, max_zoom],
        'compression': COMPRESSION_LABEL.get(internal_mode, internal_mode),
        'fields': out,
    }


def fixture_frames():
    return {
        'archive': 'tolong_flutter/datasets/qc_flood.pmtiles',
        'source_ref': 'Project NOAH flood, landslide, storm-surge and debris-flow shapefiles, '
                      'clipped to Quezon City and committed in datasets/.',
        'extracted_by': 'tools/hazard_archive_check/hazard_fields.py --extract',
        'note': 'Values are decoded from every tile; metadata tilestats in the archive is stale.',
    }


def load_json(path):
    with io.open(path, encoding='utf-8') as f:
        return json.load(f)


def save_json(path, data):
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def extract(fixture_path):
    fixture = fixture_frames()
    fixture.update(scan_archive(ARCHIVE))
    save_json(fixture_path, fixture)
    layers = ', '.join('%s=%s' % (n, f['attribute']) for n, f in sorted(fixture['fields'].items()))
    print('wrote %s (%d layers: %s)' % (fixture_path, len(fixture['fields']), layers))
    return 0


def check(fixture_path):
    fixture = load_json(fixture_path)
    actual = scan_archive(ARCHIVE)
    errors = []
    for key in ('sha256', 'size_bytes', 'spec_version', 'tiles', 'zoom_range', 'compression'):
        if fixture.get(key) != actual[key]:
            errors.append('provenance drift on %s: fixture=%r actual=%r' % (key, fixture.get(key), actual[key]))
    for layer in sorted(set(actual['fields']) - set(fixture.get('fields', {}))):
        errors.append('layer present in the archive but not in the fixture: %s' % layer)
    for layer in sorted(set(fixture.get('fields', {})) - set(actual['fields'])):
        errors.append('layer in the fixture but not in the archive: %s' % layer)
    for layer in sorted(set(actual['fields']) & set(fixture.get('fields', {}))):
        if fixture['fields'][layer] != actual['fields'][layer]:
            errors.append('field drift on %s: fixture=%r actual=%r' % (layer, fixture['fields'][layer], actual['fields'][layer]))
    if errors:
        for e in errors:
            print(e)
        print('%d mismatch(es); rerun: python tools/hazard_archive_check/hazard_fields.py --extract' % len(errors))
        return 1
    print('OK: %d layers match the committed fixture' % len(actual['fields']))
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--extract', action='store_true', help='rebuild the fixture from the archive')
    parser.add_argument('--check', action='store_true', help='compare the archive against the fixture (default)')
    parser.add_argument('--fixture', default=FIXTURE, help='fixture path')
    args = parser.parse_args(argv)
    if args.extract:
        return extract(args.fixture)
    return check(args.fixture)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
