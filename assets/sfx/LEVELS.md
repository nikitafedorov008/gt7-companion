# How loud the shipped sounds are

Measured with `ffmpeg`'s `volumedetect`, so the per-effect gains in
`lib/models/sfx.dart` are derived rather than guessed:

```sh
for f in assets/sfx/*.ogg assets/music/*.mp3; do
  ffmpeg -hide_banner -i "$f" -af volumedetect -f null - 2>&1 |
    grep -E "mean_volume|max_volume" | tr '\n' ' '
  echo "  $f"
done
```

`mean` is the level over the file's own duration — the number to compare, since a
hundred-millisecond click competes with the music for exactly that long. `peak`
shows how much headroom a file has left.

| File | Mean | Peak |
| --- | --- | --- |
| `tap.ogg` | -26.4 dB | -1.4 dB |
| `back.ogg` | -21.2 dB | -1.0 dB |
| `error.ogg` | -19.0 dB | -0.8 dB |
| `open.ogg` | -16.4 dB | -0.9 dB |
| `close.ogg` | -14.8 dB | -0.9 dB |
| `navigate.ogg` | -14.8 dB | -0.9 dB |
| `toggle.ogg` | -14.0 dB | -0.9 dB |
| `confirm.ogg` | -11.3 dB | -0.9 dB |
| `music/almost-floating.mp3` | -15.6 dB | — |
| `music/deep-space-loop.mp3` | -14.9 dB | — |

## What these numbers say

The pack is **not loudness-matched**: the press effect is 12 dB quieter than the
pack's loudest sound, so a surface that happens to ask for `tap` was far less
audible than one asking for `confirm`. That alone made some buttons feel silent
and others fine, which is exactly how it was reported.

Every file is already peak-normalised (peaks within a decibel of full scale), so
there is no headroom to raise them: normalising had to happen through the gains,
taking the quietest effect as the reference. The gains bring all eight to
-26.4 dB, and the music channel was lowered until a click clears the bed by
about nine decibels.
