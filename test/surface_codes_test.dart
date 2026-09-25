import 'package:flutter_test/flutter_test.dart';
import 'package:gt7_companion/theme/gt7_theme.dart';
import 'package:gt7_companion/widgets/telemetry/surface_codes.dart';

/// One vocabulary for packet C's surface letters: the chips used to read it, the
/// tyre cards read it, and the tyres painted on the car are tinted with it.
/// These tests pin what each letter means, because a silent change here would
/// move a colour on three different screens at once.
void main() {
  test('every letter the packet can send has a word', () {
    const codes = ['T', 'C', 'D', 'G', 'S', 's'];
    for (final code in codes) {
      expect(
        gt7SurfaceLabel(code),
        isNot('—'),
        reason: '$code has a name',
      );
    }
    expect(gt7SurfaceLabel('?'), '—', reason: 'an unknown code says so');
  });

  test('the labels are the ones the HUD prints', () {
    expect(gt7SurfaceLabel('T'), 'TARMAC');
    expect(gt7SurfaceLabel('C'), 'KERB');
    expect(gt7SurfaceLabel('D'), 'DIRT');
    expect(gt7SurfaceLabel('G'), 'GRASS');
    expect(gt7SurfaceLabel('S'), 'SAND');
    expect(gt7SurfaceLabel('s'), 'SNOW');
  });

  test('tarmac is readable text, not the tyre colour', () {
    // A tyre on tarmac is not tinted, but the *word* has to be readable: this
    // was a near-black once and "TARMAC" vanished into the card behind it.
    expect(gt7SurfaceColour('T'), gt7Text);
  });

  test('kerbs, off-track surfaces and snow each get their own colour', () {
    expect(gt7SurfaceColour('C'), gt7SlotB);
    expect(gt7SurfaceColour('G'), gt7Warn);
    expect(gt7SurfaceColour('D'), gt7Warn);
    expect(gt7SurfaceColour('S'), gt7Warn);
    expect(gt7SurfaceColour('s'), gt7SlotA);
  });

  test('off track means off the racing surface, kerbs excluded', () {
    for (final code in ['D', 'G', 'S', 's']) {
      expect(gt7SurfaceIsOffTrack(code), isTrue, reason: code);
    }
    expect(gt7SurfaceIsOffTrack('T'), isFalse);
    expect(gt7SurfaceIsOffTrack('C'), isFalse);
  });

  test('the wheel order is the packet order, front left first', () {
    expect(gt7WheelNames, ['FL', 'FR', 'RL', 'RR']);
    expect(gt7SurfaceAt('GCTT', 0), 'G');
    expect(gt7SurfaceAt('GCTT', 1), 'C');
    expect(gt7SurfaceAt('GCTT', 2), 'T');
    expect(gt7SurfaceAt('GCTT', 3), 'T');
  });

  test('a packet with no surface block reports nothing, not a default', () {
    // Packets A and B carry no surface letters. A missing wheel must come back
    // empty so the tile can say so instead of claiming tarmac.
    expect(gt7SurfaceAt('', 0), '');
    expect(gt7SurfaceAt('TC', 2), '');
    expect(gt7SurfaceAt('TTTT', 4), '');
    expect(gt7SurfaceAt('TTTT', -1), '');
  });
}
