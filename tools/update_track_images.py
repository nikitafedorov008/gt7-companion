#!/usr/bin/env python3
"""Maintain track-only artwork. No profile URLs, credentials or gallery assets.

Default skips valid existing files. --refresh-catalogue discovers all public
DG-Edge configurations and the selected GTSh course images. --check-remote
checks validators; --verify-only needs no network. Python standard library only.
"""
import argparse
import concurrent.futures
import hashlib
from html.parser import HTMLParser
import json
from pathlib import Path
import re
import threading
import time
from urllib.parse import urljoin
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parents[1]
ASSETS = ROOT / 'assets/track_images'
INDEX = ASSETS / 'manifest.json'
CATALOGUE = ROOT / 'assets/tracks/artwork_catalogue.json'
DART = ROOT / 'lib/models/daily_races/track_image_assets.dart'
HEADERS = {'User-Agent': 'gt7_companion/1.0 (+https://github.com)'}


def allowed(url):
    return bool(re.fullmatch(r'https://data\.dg-edge\.com/images/tracks/\d+/(?:cover/|thumbs/)?[A-Za-z0-9_-]+\.(?:webp|png|jpg)', url) or
                re.fullmatch(r'https://gtsh-rank\.com/images/course/\d+\.png', url))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def atomic(path, value):
    pending = path.with_suffix(path.suffix + '.tmp')
    pending.write_text(value)
    pending.replace(path)


def get(url):
    with urlopen(Request(url, headers=HEADERS), timeout=30) as response:
        return response.read().decode('utf-8')


def payload(body):
    match = re.search(r'<script[^>]+id="__NUXT_DATA__"[^>]*>(.*?)</script>', body, re.S)
    if not match:
        raise ValueError('DG-Edge public data payload missing')
    nodes = json.loads(match[1])
    def resolve(index):
        if index < 0:
            return None
        value = nodes[index]
        if isinstance(value, dict):
            return {k: resolve(v) for k, v in value.items()}
        if isinstance(value, list):
            return [resolve(v) for v in value]
        return value
    # Resolve public data only; never retain session state or csrfToken.
    data = nodes[nodes[1]['data']]
    response = nodes[next(iter(data.values()))]
    return resolve(response['payload'])


class CourseImages(HTMLParser):
    def __init__(self):
        super().__init__()
        self.urls = set()
    def handle_starttag(self, tag, attributes):
        attrs = dict(attributes)
        if tag == 'img' and 'daily-course' in attrs.get('class', '').split():
            url = urljoin('https://gtsh-rank.com', attrs.get('src', ''))
            if allowed(url):
                self.urls.add(url)


def discover():
    listing = payload(get('https://www.dg-edge.com/database/tracks'))['list']
    if not listing:
        raise ValueError('Empty track catalogue')
    def detail(row):
        data = payload(get(f'https://www.dg-edge.com/database/tracks/{row["alias"]}/{row["id"]}'))
        rows = data.get('variants') or [data]
        time.sleep(.2)
        return [{k: r.get(k) for k in ('id', 'externalId', 'name', 'fullName', 'variant', 'alias', 'images')} for r in rows]
    tracks = {}
    with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
        for rows in pool.map(detail, listing):
            for row in rows:
                tracks[str(row['id'])] = row
    course = CourseImages()
    course.feed(get('https://gtsh-rank.com/daily/'))
    return {'tracks': tracks, 'gtsh_course_urls': sorted(course.urls)}


def image_type(body):
    # This CDN labels real images application/octet-stream: trust file magic,
    # never accept an HTML error page just because the URL ends in .webp.
    if body.startswith(b'\x89PNG\r\n\x1a\n'):
        return 'png', 'image/png'
    if len(body) > 12 and body[:4] == b'RIFF' and body[8:12] == b'WEBP':
        return 'webp', 'image/webp'
    if body.startswith(b'\xff\xd8\xff'):
        return 'jpg', 'image/jpeg'
    raise ValueError('Not a supported raster image')


def selected_urls(catalogue):
    urls = set(catalogue.get('gtsh_course_urls', []))
    for row in catalogue['tracks'].values():
        for role in ('track', 'logo', 'background'):
            image = row.get('images', {}).get(role) or {}
            if not image.get('url') or not allowed(image['url']):
                raise ValueError(f'Missing/invalid {role} for track {row["id"]}')
            urls.add(image['url'])
    if not all(allowed(url) for url in urls):
        raise ValueError('Non-track image in package')
    return urls


def generate(catalogue, manifest):
    aliases = {url: item['asset'] for url, item in manifest.items()}
    by_id = {}
    for track_id, row in catalogue['tracks'].items():
        by_id[track_id] = {}
        for role, image in row['images'].items():
            if role not in ('track', 'logo', 'background'):
                continue
            url = image['url']
            by_id[track_id][role] = url
            asset = manifest[url]['asset']
            for alias in [image.get('thumbUrl'), *image.get('versions', {}).values()]:
                if alias and allowed(alias):
                    aliases[alias] = asset
    lines = ['// Generated by tools/update_track_images.py. Do not edit.',
             'const bundledTrackImages = <String, String>{']
    lines.extend(f'  {json.dumps(url)}: {json.dumps(asset)},' for url, asset in sorted(aliases.items()))
    lines += ['};', 'const bundledTrackArtworkUrls = <String, Map<String, String>>{']
    for track_id, roles in sorted(by_id.items()):
        lines.append(f'  {json.dumps(track_id)}: {{')
        lines.extend(f'    {json.dumps(role)}: {json.dumps(url)},' for role, url in sorted(roles.items()))
        lines.append('  },')
    lines.append('};\n')
    return '\n'.join(lines)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--refresh-catalogue', action='store_true')
    parser.add_argument('--check-remote', action='store_true')
    parser.add_argument('--verify-only', action='store_true')
    args = parser.parse_args()
    old = json.loads(INDEX.read_text()) if INDEX.exists() else {}
    catalogue = json.loads(CATALOGUE.read_text())
    if args.verify_only:
        required = selected_urls(catalogue)
        failures = [url for url, item in old.items() if not allowed(url) or not (ROOT / item['asset']).is_file() or sha(ROOT / item['asset']) != item['sha256']]
        if failures or not required.issubset(old):
            raise SystemExit(f'Invalid package: {len(failures)} corrupt/invalid, {len(required - old.keys())} missing URLs')
        print(f'Verified {len(old)} URLs / {len({v["asset"] for v in old.values()})} files; no network')
        return
    if args.refresh_catalogue:
        catalogue = discover()
    urls = selected_urls(catalogue) | old.keys()
    ASSETS.mkdir(parents=True, exist_ok=True)
    lock = threading.Lock()
    def update(url):
        if not allowed(url):
            raise ValueError('Not track artwork: ' + url)
        previous = old.get(url)
        valid = previous and (ROOT / previous['asset']).is_file() and sha(ROOT / previous['asset']) == previous['sha256']
        if valid and not args.check_remote:
            return url, previous, 0
        if valid and args.check_remote:
            with urlopen(Request(url, headers=HEADERS, method='HEAD'), timeout=25) as response:
                etag, modified = response.headers.get('ETag'), response.headers.get('Last-Modified')
                if (etag and etag == previous.get('etag')) or (not etag and modified and modified == previous.get('last_modified') and response.headers.get('Content-Length') == str(previous['bytes'])):
                    return url, previous, 0
        for attempt in range(3):
            try:
                with urlopen(Request(url, headers=HEADERS), timeout=30) as response:
                    body = response.read()
                    ext, mime = image_type(body)
                    digest = hashlib.sha256(body).hexdigest()
                    path = ASSETS / f'{digest}.{ext}'
                    with lock:
                        if not path.exists() or sha(path) != digest:
                            pending = path.with_suffix(path.suffix + '.tmp')
                            pending.write_bytes(body)
                            pending.replace(path)
                    item = {'asset': str(path.relative_to(ROOT)), 'sha256': digest, 'bytes': len(body), 'mime': mime,
                            'etag': response.headers.get('ETag'), 'last_modified': response.headers.get('Last-Modified')}
                time.sleep(.1)
                return url, item, len(body)
            except Exception:
                if attempt == 2:
                    raise
                time.sleep(attempt + 1)
    result, transferred = {}, 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=6) as pool:
        for url, item, count in pool.map(update, sorted(urls)):
            result[url] = item
            transferred += count
    # Publish only once the complete required set has downloaded successfully.
    atomic(CATALOGUE, json.dumps(catalogue, ensure_ascii=False, indent=2) + '\n')
    atomic(INDEX, json.dumps(result, ensure_ascii=False, sort_keys=True, indent=2) + '\n')
    atomic(DART, generate(catalogue, result))
    used = {ROOT / item['asset'] for item in result.values()}
    for path in ASSETS.iterdir():
        if re.fullmatch(r'[0-9a-f]{64}\.(?:png|jpg|webp)', path.name) and path not in used:
            path.unlink()
    print(f'Updated {len(result)} URLs / {len(used)} files; downloaded {transferred} bytes')


if __name__ == '__main__':
    main()
