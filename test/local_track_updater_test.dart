import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('track updater validators, repair, dedup and URL allowlist', () async {
    final result = await Process.run('python3', [
      '-c',
      r'''
import hashlib,importlib.util,io,json,sys,tempfile
from pathlib import Path
from unittest.mock import patch
from contextlib import redirect_stdout
spec=importlib.util.spec_from_file_location('updater','tools/update_track_images.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
a='https://data.dg-edge.com/images/tracks/1/Back1.webp'
b='https://data.dg-edge.com/images/tracks/2/Back2.webp'
body=b'RIFF0000WEBPfirst';etag='v1';calls=[]
class Response:
 def __init__(self):self.headers={'Content-Type':'application/octet-stream','ETag':etag,'Content-Length':str(len(body))}
 def __enter__(self):return self
 def __exit__(self,*args):pass
 def read(self):return body
def request(req,**kwargs):calls.append(req.get_method());return Response()
with tempfile.TemporaryDirectory() as directory:
 m.ROOT=Path(directory);m.ASSETS=m.ROOT/'assets/track_images';m.INDEX=m.ASSETS/'manifest.json'
 m.CATALOGUE=m.ROOT/'catalogue.json';m.DART=m.ROOT/'index.dart'
 row={'id':'1','images':{role:{'url':a} for role in ['track','logo','background']}}
 m.CATALOGUE.write_text(json.dumps({'tracks':{'1':row},'gtsh_course_urls':[]}))
 def run(*flags):
  calls.clear()
  with patch.object(sys,'argv',['updater',*flags]),patch.object(m,'urlopen',request),patch.object(m.time,'sleep'),redirect_stdout(io.StringIO()):m.main()
 run();assert calls==['GET']
 run();assert calls==[]
 run('--check-remote');assert calls==['HEAD']
 body=b'RIFF0000WEBPchanged';etag='v2'
 run('--check-remote');assert calls==['HEAD','GET']
 item=json.loads(m.INDEX.read_text())[a];assert item['sha256']==hashlib.sha256(body).hexdigest()
 assert len(list(m.ASSETS.glob('*.webp')))==1
 image=m.ROOT/item['asset'];image.write_bytes(b'corrupt')
 try:run('--verify-only')
 except SystemExit:pass
 else:raise AssertionError('corrupt file accepted')
 run();assert calls==['GET'];assert image.read_bytes()==body
 run('--verify-only');assert calls==[]
 data=json.loads(m.CATALOGUE.read_text());data['tracks']['2']={'id':'2','images':{role:{'url':b} for role in ['track','logo','background']}};m.CATALOGUE.write_text(json.dumps(data))
 run();assert calls==['GET'];assert len(list(m.ASSETS.glob('*.webp')))==1
 assert not m.allowed('https://data.dg-edge.com/images/avatars/1.webp')
 assert not m.allowed('https://gtsh-rank.com/images/profile/1.png')
 try:m.image_type(b'<html>error</html>')
 except ValueError:pass
 else:raise AssertionError('HTML accepted as image')
 print('track updater regression passed')
''',
    ]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
