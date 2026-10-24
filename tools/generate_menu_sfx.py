"""Generate the original soft menu sound bank. Python stdlib only.

Rounded sine/electric-piano partials, 6ms attack, no noise or sampled game audio.
Run from any directory; results are deterministic 44.1kHz mono PCM16 WAV.
"""
import math
from pathlib import Path
import struct
import wave

RATE = 44100
ROOT = Path(__file__).resolve().parents[1]
# (offset seconds, frequency Hz, duration seconds, relative amplitude)
CUES = {
    'tap': [(0, 880, .095, 1)],
    'navigate': [(0, 659.255, .12, .8), (.045, 987.767, .16, 1)],
    'back': [(0, 783.991, .12, .8), (.045, 523.251, .16, 1)],
    'open': [(0, 523.251, .19, 1), (.025, 783.991, .18, .55)],
    'close': [(0, 587.330, .17, 1), (.025, 391.995, .18, .55)],
    'toggle': [(0, 739.989, .115, 1), (.018, 1108.731, .095, .3)],
    'confirm': [(0, 523.251, .14, .8), (.07, 659.255, .14, .8), (.14, 987.767, .2, 1)],
    'error': [(0, 293.665, .17, 1), (.09, 261.626, .2, .8)],
}
for name, notes in CUES.items():
    length = math.ceil((max(t + d for t, _, d, _ in notes) + .015) * RATE)
    samples = [0.] * length
    for offset, freq, duration, amplitude in notes:
        for i in range(math.ceil(duration * RATE)):
            t = i / RATE
            attack = math.sin(min(t / .006, 1) * math.pi / 2) ** 2
            release = min((duration - t) / .025, 1) ** 2
            envelope = attack * release * math.exp(-t / (duration * .24))
            phase = 2 * math.pi * freq * t
            tone = math.sin(phase) + .12 * math.sin(phase * 2) + .025 * math.sin(phase * 3)
            samples[round(offset * RATE) + i] += amplitude * envelope * tone
    rms = math.sqrt(sum(x*x for x in samples) / len(samples))
    gain = 10 ** (-24 / 20) / rms
    samples = [x * gain for x in samples]
    assert max(abs(x) for x in samples) < .5
    path = ROOT / 'assets' / 'sfx' / f'{name}.wav'
    with wave.open(str(path), 'wb') as output:
        output.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        output.writeframes(b''.join(struct.pack('<h', round(x * 32767)) for x in samples))
    print(f'{name}: {len(samples)/RATE:.3f}s RMS -24.00dBFS peak {20*math.log10(max(abs(x) for x in samples)):.2f}dBFS')
