import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'updater skips unchanged files, replaces changed files and repairs corrupt files',
    () async {
      final result = await Process.run('python3', [
        '-c',
        r'''
import hashlib, importlib.util, io, json, sys, tempfile
from contextlib import redirect_stdout
from pathlib import Path
from unittest.mock import patch
spec=importlib.util.spec_from_file_location('updater','tools/update_card_images.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
url='https://www.gran-turismo.com/common/dist/gt7/carlist/car_thumbnails/car102.png'
body=b'old-image';etag='v1';calls=[]
class Response:
    status=200
    def __init__(self):self.headers={'Content-Type':'image/png','ETag':etag,'Content-Length':str(len(body))}
    def __enter__(self):return self
    def __exit__(self,*args):pass
    def read(self):return body

def request(req,**kwargs):
    calls.append(req.get_method())
    return Response()

with tempfile.TemporaryDirectory() as directory:
    m.ROOT=Path(directory);m.ASSETS=m.ROOT/'assets/card_images';m.INDEX=m.ASSETS/'manifest.json'
    m.DART=m.ROOT/'lib/models/car_dealer/card_image_assets.dart';m.DART.parent.mkdir(parents=True)
    (m.ROOT/'assets/cars').mkdir(parents=True);(m.ROOT/'assets/cars/cars.json').write_text('{}')
    manifest=m.ROOT/'seed.json';manifest.write_text(json.dumps([{'url':url,'ok':True,'sha256':hashlib.sha256(body).hexdigest()}]))
    def run(*flags):
        calls.clear()
        with patch.object(sys,'argv',['updater','--manifest',str(manifest),*flags]),patch.object(m,'urlopen',request),patch.object(m.time,'sleep'),redirect_stdout(io.StringIO()):m.main()
    run();assert calls==['GET']
    run();assert calls==[]
    run('--check-remote');assert calls==['HEAD']
    body=b'changed-image';etag='v2'
    run('--check-remote');assert calls==['HEAD','GET']
    item=json.loads(m.INDEX.read_text())[url];assert item['sha256']==hashlib.sha256(body).hexdigest()
    assert len(list(m.ASSETS.glob('*.png')))==1,'superseded generated files should be pruned'
    run();assert calls==[],'a stale audit seed must not undo a verified remote update'
    image=m.ROOT/item['asset'];image.write_bytes(b'corrupt')
    try:run('--verify-only')
    except SystemExit:pass
    else:raise AssertionError('corrupt image was not detected')
    run();assert calls==['GET'];assert image.read_bytes()==body
    run('--verify-only');assert calls==[]
    assert url in m.DART.read_text()
    second=url.replace('car102.png','car103.png')
    manifest.write_text(json.dumps([{'url':url},{'url':second}]))
    run('--check-remote')
    entries=json.loads(m.INDEX.read_text())
    assert entries[url]['asset']==entries[second]['asset']
    assert len(list(m.ASSETS.glob('*.png')))==1,'identical bodies must share one asset'
print('updater regression checks passed')
''',
      ]);
      expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
      expect(
        result.stdout.toString(),
        contains('updater regression checks passed'),
      );
    },
  );
}
