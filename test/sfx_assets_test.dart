import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/models/sfx.dart';
import 'package:gt7_companion/services/music_service.dart';

void main() {
  for (final effect in Sfx.values) {
    test(
      '${effect.name} ships audible PCM samples, not a renamed compressed file',
      () {
        final bytes = File(effect.asset).readAsBytesSync();
        final data = ByteData.sublistView(bytes);
        String tag(int offset) =>
            String.fromCharCodes(bytes.sublist(offset, offset + 4));
        expect(tag(0), 'RIFF');
        expect(tag(8), 'WAVE');
        var foundFormat = false;
        var foundSamples = false;
        for (var offset = 12; offset + 8 <= bytes.length;) {
          final size = data.getUint32(offset + 4, Endian.little);
          final start = offset + 8;
          expect(start + size, lessThanOrEqualTo(bytes.length));
          if (tag(offset) == 'fmt ') {
            expect(
              data.getUint16(start, Endian.little),
              1,
              reason: 'uncompressed PCM',
            );
            expect(data.getUint16(start + 14, Endian.little), 16);
            foundFormat = true;
          }
          if (tag(offset) == 'data') {
            var peak = 0;
            var squareSum = 0.0;
            var count = 0;
            for (var i = start; i + 1 < start + size; i += 2) {
              final sample = data.getInt16(i, Endian.little);
              peak = math.max(peak, sample.abs());
              squareSum += sample * sample;
              count++;
            }
            expect(size, greaterThan(1000));
            expect(
              peak,
              greaterThan(3276),
              reason: 'the decoded transient must not disappear',
            );
            final rmsDb =
                20 * math.log(math.sqrt(squareSum / count) / 32767) / math.ln10;
            expect(rmsDb, closeTo(-24, 0.1));
            expect(peak, lessThan(16384), reason: 'at least 6dB headroom');
            foundSamples = true;
          }
          offset = start + size + (size % 2);
        }
        expect(foundFormat && foundSamples, isTrue);
      },
    );
  }

  test('the music rotation ships its files and author attribution', () {
    for (final track in MusicService.tracks) {
      expect(File(track).lengthSync(), greaterThan(100000));
    }
    expect(MusicService.credits, contains('Kevin MacLeod'));
    expect(
      MusicService.credits,
      contains('creativecommons.org/licenses/by/4.0/'),
    );
  });
}
