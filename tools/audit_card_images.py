#!/usr/bin/env python3
"""Measure card images only, from repository metadata and a public GTDB snapshot.

Never imports or executes downloaded JS. Galleries are excluded by selection.
GET bodies are counted/hashed, then discarded; only public metadata is retained.
Run with --input-dir pointing to gt7info.json, legendary.json, used_dom.json,
and gtdb_catalogue_rows.json. Use the browser to export the latter two from
GTDB's used-cars and all-cars pages; this keeps source discovery reviewable.
"""
import argparse
import concurrent.futures
import csv
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import time
from urllib.parse import urlparse
from urllib.request import Request, urlopen
from datetime import datetime, timezone

GT = 'https://www.gran-turismo.com/common/dist/gt7/carlist/'
CDN = 'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/'
ALLOWED = {'www.gran-turismo.com', 'imagedelivery.net', 'gtdb.io', 'vl.imgix.net', 'flagcdn.com'}


def request(url, accept='*/*'):
    if urlparse(url).hostname not in ALLOWED:
        raise ValueError('Unexpected image/source host')
    return urlopen(Request(url, headers={
        'User-Agent': 'GT7Companion-CardPhotoAudit/1.0',
        'Accept': accept, 'Accept-Encoding': 'identity',
    }), timeout=25)


class Images(HTMLParser):
    def __init__(self):
        super().__init__()
        self.images = []

    def handle_starttag(self, tag, attrs):
        if tag == 'img':
            self.images.append(dict(attrs))


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument('--input-dir', type=Path, required=True)
    ap.add_argument('--output-dir', type=Path, required=True)
    ap.add_argument('--refresh', action='store_true', help='Re-measure URLs instead of resuming cached successful results')
    args = ap.parse_args()
    inputs, out = args.input_dir, args.output_dir
    out.mkdir(parents=True, exist_ok=True)
    cache = inputs / 'pages'
    cache.mkdir(exist_ok=True)
    catalogue = json.loads(Path('assets/cars/cars.json').read_text())
    brands = json.loads(Path('assets/cars/brand_central.json').read_text())['brands']
    info = json.loads((inputs / 'gt7info.json').read_text())
    legend = json.loads((inputs / 'legendary.json').read_text())['data']['gt_car']
    used = json.loads((inputs / 'used_dom.json').read_text())
    rows = json.loads((inputs / 'gtdb_catalogue_rows.json').read_text())
    sources = {}

    def add(url, group, origin):
        if not url:
            return
        entry = sources.setdefault(url, {'url': url, 'groups': set(), 'origins': set()})
        entry['groups'].add(group)
        entry['origins'].add(origin)

    for car in catalogue:
        add(GT + 'car_thumbnails/' + car + '.png', 'official_thumbnail', 'catalogue:' + car)
    for dealer in ['used', 'legend']:
        for car in info[dealer]['cars']:
            add(GT + 'car_thumbnails/car' + car['carid'] + '.png', 'official_thumbnail', dealer + ':' + car['carid'])
    for item in used:
        add(item['url'], 'gtdb_used', 'used-current:' + item['card'])
    for car in legend:
        if car.get('frontImage'):
            add(CDN + car['frontImage'] + '/public', 'gtdb_legendary', 'legend-current:' + car['name'])
    # These files are artwork used by the cards but are not photos of cars.
    for brand in brands:
        add(GT + 'tuner_logos/dark/' + brand + '.png', 'support_brand_logo', 'brand-central:' + brand)
    for dealer in ['used', 'legend']:
        for car in info[dealer]['cars']:
            if car.get('region') and dealer == 'used':
                add('https://flagcdn.com/h24/' + car['region'] + '.png', 'support_flag', 'used-flag:' + car['region'])
            if dealer == 'legend':
                name = car['manufacturer'].lower().replace(' ', '-')
                add('https://vl.imgix.net/img/' + name + '-logo.png', 'support_dealer_logo', 'legend-logo:' + car['manufacturer'])

    dealer_rows = [r for r in rows if 'Used Cars' in r['text'] or 'Legend Cars' in r['text']]

    def discover(row):
        url = row['href']
        page = cache / (hashlib.sha256(url.encode()).hexdigest() + '.html')
        try:
            if page.exists() and not args.refresh:
                body = page.read_text()
            else:
                last = None
                for attempt in range(3):
                    try:
                        with request(url) as response:
                            body = response.read().decode('utf-8')
                        page.write_text(body)
                        break
                    except Exception as error:
                        last = error
                        time.sleep(1 + attempt)
                else:
                    raise last
                time.sleep(.25)
            parser = Images()
            parser.feed(body)
            # Select only images used by dealer cards, never Photo 1/2/... galleries.
            group = 'gtdb_used' if 'Used Cars' in row['text'] else 'gtdb_legendary'
            selected = [i for i in parser.images if (
                'Used Car Dealer Photo' in i.get('alt', '') if group == 'gtdb_used'
                else 'Hagerty, Learn More (Front)' in i.get('alt', '')
            ) and i.get('src', '').startswith(CDN)]
            return {'page': url, 'group': group, 'photos': [i['src'] for i in selected]}
        except Exception as error:
            return {'page': url, 'error': str(error)}

    discovery = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=3) as pool:
        for result in pool.map(discover, dealer_rows):
            discovery.append(result)
            for url in result.get('photos', []):
                add(url, result['group'], result['page'])
            if len(discovery) % 20 == 0:
                print('discovery', len(discovery), '/', len(dealer_rows), flush=True)
    (out / 'discovery.json').write_text(json.dumps(discovery, ensure_ascii=False, indent=2))
    manifest = [{**v, 'groups': sorted(v['groups']), 'origins': sorted(v['origins'])} for v in sources.values()]
    (out / 'manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2))
    results_cache = inputs / 'measurements.json'
    measured = json.loads(results_cache.read_text()) if results_cache.exists() and not args.refresh else {}

    def measure(entry):
        url = entry['url']
        if url in measured and measured[url].get('ok'):
            return {**entry, **measured[url]}
        avif = url.startswith(CDN)
        accept = 'image/avif' if avif else '*/*'
        for attempt in range(3):
            try:
                with request(url, accept) as response:
                    kind = response.headers.get('Content-Type', '').split(';')[0]
                    if not kind.startswith('image/'):
                        raise ValueError('Non-image response: ' + kind)
                    digest, length = hashlib.sha256(), 0
                    while chunk := response.read(65536):
                        digest.update(chunk)
                        length += len(chunk)
                    result = {**entry, 'ok': True, 'bytes': length, 'sha256': digest.hexdigest(),
                              'content_type': kind, 'accept': accept, 'status': response.status,
                              'final_url': response.url}
                time.sleep(.15)
                return result
            except Exception as error:
                if attempt == 2:
                    return {**entry, 'ok': False, 'error': str(error), 'accept': accept}
                time.sleep(1 + attempt)

    results = []
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for result in pool.map(measure, manifest):
            results.append(result)
            measured[result['url']] = {k: v for k, v in result.items() if k not in {'groups', 'origins'}}
            if len(results) % 40 == 0:
                results_cache.write_text(json.dumps(measured))
                print('measured', len(results), '/', len(manifest), flush=True)
    results_cache.write_text(json.dumps(measured))
    (out / 'measurements.json').write_text(json.dumps(results, ensure_ascii=False, indent=2))
    groups = {}
    for group in sorted({g for r in results for g in r['groups']}):
        entries = [r for r in results if group in r['groups']]
        ok = [r for r in entries if r.get('ok')]
        unique = {r['sha256']: r['bytes'] for r in ok}
        groups[group] = {'urls': len(entries), 'ok': len(ok), 'failed': len(entries) - len(ok),
                         'bytes': sum(r['bytes'] for r in ok), 'unique_contents': len(unique),
                         'deduplicated_bytes': sum(unique.values())}
    def total(entries):
        ok = [r for r in entries if r.get('ok')]
        unique = {r['sha256']: r['bytes'] for r in ok}
        return {'urls': len(entries), 'ok': len(ok), 'failed': len(entries)-len(ok),
                'url_deduplicated_bytes': sum(r['bytes'] for r in ok),
                'unique_contents': len(unique), 'content_deduplicated_bytes': sum(unique.values())}
    photo_rows = [r for r in results if any(not g.startswith('support_') for g in r['groups'])]
    summary = {'captured_utc': datetime.now(timezone.utc).isoformat(), 'official_cars': len(catalogue),
               'gtdb_catalogue_cars': len(rows), 'gtdb_dealer_pages': len(dealer_rows),
               'discovery_failed': [d for d in discovery if 'error' in d],
               'pages_without_dealer_photo': [d for d in discovery if not d.get('photos') and 'error' not in d],
               'groups': groups, 'photos_only': total(photo_rows), 'with_support_artwork': total(results),
               'failures': [r for r in results if not r.get('ok')]}
    (out / 'summary.json').write_text(json.dumps(summary, ensure_ascii=False, indent=2))
    (out / 'photos-only.json').write_text(json.dumps(photo_rows, ensure_ascii=False, indent=2))
    unique_files = {}
    for result in results:
        if not result.get('ok'):
            continue
        item = unique_files.setdefault(result['sha256'], {
            'sha256': result['sha256'], 'bytes': result['bytes'],
            'content_type': result['content_type'], 'urls': [], 'groups': set(),
        })
        item['urls'].append(result['url'])
        item['groups'].update(result['groups'])
    for item in unique_files.values():
        item['groups'] = sorted(item['groups'])
    (out / 'unique-files.json').write_text(json.dumps(list(unique_files.values()), ensure_ascii=False, indent=2))
    with (out / 'photos.csv').open('w', newline='') as stream:
        writer = csv.writer(stream)
        writer.writerow(['url', 'groups', 'bytes', 'content_type', 'sha256'])
        for result in photo_rows:
            writer.writerow([result['url'], ';'.join(result['groups']),
                             result.get('bytes', ''), result.get('content_type', ''),
                             result.get('sha256', '')])
    print(json.dumps({k:v for k,v in summary.items() if k not in {'failures','pages_without_dealer_photo','discovery_failed'}},indent=2))


if __name__ == '__main__':
    main()
