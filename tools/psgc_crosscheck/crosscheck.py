#!/usr/bin/env python3
"""Cross-check tolong_flutter barangay data against the official PSA PSGC masterlist.

psa.gov.ph refuses automated downloads (HTTP 403), so the masterlist datafile is
obtained from a mirror; the committed fixture records the exact provenance.

Modes:
  --extract FLAT_JSON  Rebuild the fixture from a mirror copy of the PSGC datafile
                       (the barangay_flat.json format of github.com/bendlikeabamboo/barangay:
                        a flat list of {"name","type","psgc_id","parent_psgc_id"}).
  --check              Compare assets/data/qc_barangays.json against the fixture
                       (code set and name per code must match exactly, 142 entries,
                       all codes 10-digit). Exits 1 on any mismatch.

Stdlib only. Run from anywhere; paths resolve relative to the repository root.
"""

import argparse
import io
import json
import os
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
QC_PSGC = '1381300000'
APP_DATA = os.path.join(REPO_ROOT, 'tolong_flutter', 'assets', 'data', 'qc_barangays.json')
FIXTURE = os.path.join(REPO_ROOT, 'tolong_flutter', 'test', 'fixtures', 'psgc_qc_official.json')


def load_json(path):
    with io.open(path, encoding='utf-8') as f:
        return json.load(f)


def save_json(path, data):
    with io.open(path, 'w', encoding='utf-8', newline='\n') as f:
        json.dump(data, f, ensure_ascii=False, indent=2)
        f.write('\n')


def extract(flat_json_path, fixture_path):
    flat = load_json(flat_json_path)
    official = {
        x['psgc_id']: x['name']
        for x in flat
        if x.get('parent_psgc_id') == QC_PSGC
    }
    if len(official) != 142:
        print('error: expected 142 barangays for %s, got %d' % (QC_PSGC, len(official)))
        return 1
    fixture = load_json(fixture_path) if os.path.exists(fixture_path) else {}
    fixture.update({
        'barangays': [
            {'psgc': c, 'name': official[c]} for c in sorted(official)
        ],
        'city': {'name': 'Quezon City', 'psgc': QC_PSGC},
    })
    fixture.setdefault('source', '')
    fixture.setdefault('obtained_from', '')
    fixture.setdefault('cross_checked', [])
    fixture.setdefault('retrieved', '')
    save_json(fixture_path, fixture)
    print('wrote %d entries to %s' % (len(official), fixture_path))
    return 0


def check(fixture_path, app_path):
    fixture = load_json(fixture_path)
    app = load_json(app_path)
    official = {b['psgc']: b['name'] for b in fixture['barangays']}
    actual = {b['psgc']: b['name'] for b in app['barangays']}
    errors = []

    if len(app['barangays']) != 142:
        errors.append('app data has %d entries, expected 142' % len(app['barangays']))
    bad_codes = sorted(p for p in actual if len(p) != 10 or not p.isdigit())
    if bad_codes:
        errors.append('app data has non-10-digit codes: %s' % ', '.join(bad_codes))

    for code in sorted(set(official) - set(actual)):
        errors.append('missing in app: %s (%s)' % (code, official[code]))
    for code in sorted(set(actual) - set(official)):
        errors.append('not official: %s (%s)' % (code, actual[code]))
    for code in sorted(set(actual) & set(official)):
        if actual[code] != official[code]:
            errors.append('name mismatch %s: app=%r official=%r' % (code, actual[code], official[code]))

    if errors:
        for e in errors:
            print(e)
        print('%d mismatch(es)' % len(errors))
        return 1
    print('OK: 142 barangays match the official PSGC fixture')
    return 0


def main(argv):
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument('--extract', metavar='FLAT_JSON', help='rebuild fixture from a mirror datafile')
    parser.add_argument('--check', action='store_true', help='compare app data against the fixture (default)')
    parser.add_argument('--fixture', default=FIXTURE, help='fixture path')
    parser.add_argument('--app', default=APP_DATA, help='app data path')
    args = parser.parse_args(argv)

    if args.extract:
        return extract(args.extract, args.fixture)
    return check(args.fixture, args.app)


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
