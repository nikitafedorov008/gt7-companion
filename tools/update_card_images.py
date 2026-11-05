#!/usr/bin/env python3
"""Update the offline card artwork package (never galleries).

Default: download only missing/new files from the audited URL manifest. Existing
files are verified by SHA-256. --check-remote checks HTTP validators for updates.
--verify-only is completely offline. Run fetch_gt7_cars.py and a fresh image
audit to extend the seed after catalogue changes; new current-dealer photos can
also be supplied through --manifest. Files are content-addressed and written
atomically. Do not run with certificate validation disabled.
"""
import argparse
import concurrent.futures
import hashlib
import json
import re
from html.parser import HTMLParser
from datetime import datetime, timezone
from pathlib import Path
import time
import threading
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/card_images'
INDEX = ASSETS / 'manifest.json'
DART = ROOT / 'lib/models/car_dealer/card_image_assets.dart'


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


class Node:
    def __init__(self, tag='', attrs=None):
        self.tag, self.attrs, self.children = tag, dict(attrs or []), []
    def all(self):
        yield self
        for child in self.children:
            if isinstance(child, Node): yield from child.all()
    def text(self):
        return ' '.join(c.text() if isinstance(c, Node) else c for c in self.children)

class Document(HTMLParser):
    def __init__(self, body):
        super().__init__(convert_charrefs=True)
        self.root = Node(); self.stack = [self.root]; self.feed(body)
    def handle_starttag(self, tag, attrs):
        node = Node(tag, attrs); self.stack[-1].children.append(node)
        if tag not in {'area','base','br','col','embed','hr','img','input','link','meta','param','source','track','wbr'}:
            self.stack.append(node)
    def handle_endtag(self, tag):
        for i in range(len(self.stack)-1, 0, -1):
            if self.stack[i].tag == tag:
                del self.stack[i:]; break
    def handle_data(self, text): self.stack[-1].children.append(text)

def used_rows(body, links):
    rows = {}
    for node in Document(body).root.all():
        if node.tag != 'div' or not {'grid', 'grid-cols-2'}.issubset(node.attrs.get('class','').split()): continue
        children = list(node.all())
        anchors = [n for n in children if n.tag == 'a' and n.attrs.get('href','').startswith('/gt7/car/')]
        price = re.search(r'Cr\.\s*([\d,]+)', node.text())
        if len(anchors) != 1 or not price: continue
        slug = anchors[0].attrs['href'].strip('/').split('/')[-1]
        car = links.get(slug) or links.get('name:' + re.sub(r'[^a-z0-9]', '', anchors[0].text().strip().lower()))
        if car is None: continue
        car_id = int(car['id'].removeprefix('car'))
        images = [n.attrs['src'] for n in children if n.tag == 'img' and n.attrs.get('src','').startswith('https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/')]
        text = node.text(); details = {'id': f'#CAR{car_id}', 'in_ucd': True,
            'used_price': int(price[1].replace(',','')),
            'used_state': 'soldout' if 'SOLD OUT' in text else 'limited' if 'Limited Stock' in text else 'new' if 'NEW' in text else 'normal'}
        if images: details['used_car_image_id'] = images[0].split('/')[-2]
        rows[car_id] = {'id': car_id, 'name': anchors[0].text().strip(), 'short_name': anchors[0].text().strip(),
                        'slug': slug, 'manufacturer': {'name': car['manufacturer']}, 'details': details}
    if not rows: raise ValueError('Used source has no mapped dealer rows')
    return list(rows.values())

def build_links():
    path = ROOT / 'assets/cars/dealer_car_links.json'
    links = json.loads(path.read_text())
    cars = json.loads((ROOT / 'assets/cars/cars.json').read_text())
    brands = json.loads((ROOT / 'assets/cars/brand_central.json').read_text())['brands']
    aliases, ambiguous = {}, set()
    for car_id, car in cars.items():
        for name in [car['name'], car['short']]:
            key = 'name:' + re.sub(r'[^a-z0-9]', '', name.lower())
            item = {'id':car_id,'manufacturer':brands[car['maker']]['name'].strip()}
            if key in aliases and aliases[key]['id'] != car_id:
                ambiguous.add(key)
            aliases[key] = item
    for key in ambiguous: aliases.pop(key, None)
    links = {k:v for k,v in links.items() if not k.startswith('name:')}
    links.update(aliases)
    path.write_text(json.dumps(links,ensure_ascii=False,indent=2)+'\n')
    return links

def refresh_dealers():
    def get(url):
        with urlopen(Request(url, headers={'User-Agent':'GT7Companion-CardPhotoAudit/1.0'}),timeout=25) as response:
            return response.read().decode('utf-8')
    info = json.loads(get('https://ddm999.github.io/gt7info/data.json'))
    links = build_links()
    used = used_rows(get('https://gtdb.io/gt7/used-cars/'), links)
    legend = json.loads(get('https://gtdb.io/api/graphql_middleware/query/LegendCarsDealer'))['data']['gt_car']
    if not info['used']['cars'] or not info['legend']['cars'] or not legend: raise ValueError('Incomplete dealer snapshot')
    data = {'captured_utc':datetime.now(timezone.utc).isoformat(),'gt7info':info,'gtdb_used':used,'gtdb_legendary':legend}
    path = ROOT / 'assets/cars/dealer_snapshot.json'
    temporary = path.with_suffix('.json.tmp'); temporary.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n'); temporary.replace(path)
    return data

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--manifest', type=Path, default=ROOT / 'docs/research/card-photo-audit-2026-11-04/measurements.json')
    parser.add_argument('--check-remote', action='store_true')
    parser.add_argument('--refresh-dealers', action='store_true', help='Refresh bundled inventory from the live public sources and add their new artwork')
    parser.add_argument('--verify-only', action='store_true')
    args = parser.parse_args()
    ASSETS.mkdir(parents=True, exist_ok=True)
    old = json.loads(INDEX.read_text()) if INDEX.exists() else {}
    if args.verify_only:
        failures = [url for url, item in old.items() if not (ROOT / item['asset']).exists() or digest(ROOT / item['asset']) != item['sha256']]
        if not old or failures:
            raise SystemExit(f'Invalid package: {len(failures)} missing/corrupt files; entries={len(old)}')
        print(f'Verified {len(old)} URLs / {len({v["asset"] for v in old.values()})} files; {sum(p.stat().st_size for p in {ROOT / v["asset"] for v in old.values()})} bytes; no network')
        return
    seed = json.loads(args.manifest.read_text())
    rows = {r['url']: r for r in seed if r.get('ok', True)}
    for url, item in old.items():
        rows.setdefault(url, {'url': url, **item})
    if args.refresh_dealers:
        snapshot = refresh_dealers()
        for car in snapshot['gtdb_used']:
            image = car['details'].get('used_car_image_id')
            if image:
                url = f'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/{image}/public'
                rows.setdefault(url, {'url':url})
        for car in snapshot['gtdb_legendary']:
            if car.get('frontImage'):
                url = f"https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/{car['frontImage']}/public"
                rows.setdefault(url, {'url':url})
    # New official catalogue entries join the package without downloading galleries.
    for car in json.loads((ROOT / 'assets/cars/cars.json').read_text()):
        url = 'https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/' + car + '.png'
        rows.setdefault(url, {'url':url})
    transferred = 0
    asset_write_lock = threading.Lock()

    def update(row):
        url = row['url']
        if not url.startswith(('https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/',
                               'https://www.gran-turismo.com/common/dist/gt7/carlist/tuner_logos/',
                               'https://imagedelivery.net/nkaANmEhdg2ZZ4vhQHp4TQ/',
                               'https://flagcdn.com/h24/', 'https://vl.imgix.net/img/')):
            raise ValueError('Not a card/support image URL: ' + url)
        previous = old.get(url)
        valid = previous and (ROOT / previous['asset']).exists() and digest(ROOT / previous['asset']) == previous['sha256']
        if valid and not args.check_remote:
            return url, previous, 0
        accept = row.get('accept') or ('image/avif' if 'imagedelivery.net' in url else '*/*')
        headers = {'User-Agent': 'GT7Companion-CardArtworkUpdater/1.0', 'Accept': accept, 'Accept-Encoding': 'identity'}
        if valid and args.check_remote:
            with urlopen(Request(url, headers=headers, method='HEAD'), timeout=25) as response:
                etag, modified = response.headers.get('ETag'), response.headers.get('Last-Modified')
                if (etag and etag == previous.get('etag')) or (not etag and modified and modified == previous.get('last_modified') and response.headers.get('Content-Length') == str(previous['bytes'])):
                    return url, previous, 0
        last = None
        for attempt in range(3):
            try:
                with urlopen(Request(url, headers=headers), timeout=30) as response:
                    body = response.read()
                    mime = response.headers.get('Content-Type', '').split(';')[0]
                    if mime not in {'image/png', 'image/jpeg', 'image/avif', 'image/webp', 'image/svg+xml'}:
                        raise ValueError('Unexpected image type: ' + mime)
                    sha = hashlib.sha256(body).hexdigest()
                    expected = previous['sha256'] if previous else row.get('sha256')
                    if not args.check_remote and expected and expected != sha:
                        raise ValueError('Source changed since audit; review with --check-remote: ' + url)
                    extension = {'image/png': 'png', 'image/jpeg': 'jpg', 'image/avif': 'avif', 'image/webp': 'webp', 'image/svg+xml': 'svg'}[mime]
                    path = ASSETS / f'{sha}.{extension}'
                    with asset_write_lock:
                        if not path.exists() or digest(path) != sha:
                            temporary = path.with_suffix(path.suffix + '.tmp')
                            temporary.write_bytes(body)
                            temporary.replace(path)
                    item = {'asset': str(path.relative_to(ROOT)), 'sha256': sha, 'bytes': len(body), 'mime': mime,
                            'etag': response.headers.get('ETag'), 'last_modified': response.headers.get('Last-Modified')}
                time.sleep(.1)
                return url, item, len(body)
            except Exception as error:
                last = error
                time.sleep(attempt + 1)
        raise last

    result = {}
    # Do not publish an incomplete manifest: successfully downloaded files are
    # harmless until the validated index is atomically replaced.
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for url, item, count in pool.map(update, rows.values()):
            result[url] = item
            transferred += count
            if len(result) % 80 == 0:
                print(f'{len(result)}/{len(rows)} images; transferred {transferred} bytes', flush=True)
    pending = INDEX.with_suffix('.json.tmp')
    pending.write_text(json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + '\n')
    pending.replace(INDEX)
    data = ['// Generated by tools/update_card_images.py. Do not edit.',
            'const bundledCardImages = <String, String>{']
    data.extend(f'  {json.dumps(url)}: {json.dumps(item["asset"])},' for url, item in sorted(result.items()))
    data.append('};\n')
    dart_pending = DART.with_suffix('.dart.tmp')
    dart_pending.write_text('\n'.join(data))
    dart_pending.replace(DART)
    referenced = {ROOT / item['asset'] for item in result.values()}
    for path in ASSETS.iterdir():
        if re.fullmatch(r'[0-9a-f]{64}\.(?:png|jpg|avif|webp|svg)', path.name) and path not in referenced:
            path.unlink()
    print(f'Updated {len(result)} URLs, {len({v["asset"] for v in result.values()})} files; downloaded {transferred} bytes')


if __name__ == '__main__':
    main()
