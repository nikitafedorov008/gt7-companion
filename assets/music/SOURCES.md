# Ambient background music

Two tracks from **Open Lo-Fi**, a collection of 166 lo-fi tracks that its author
btahir generated with Suno v5 and donated to the public domain.

- Collection: https://github.com/btahir/open-lofi
- License: **CC0 1.0 Universal** — stated in the repository README and its
  `catalog.json` (`"license": "CC0-1.0"`), and in the release archive's own
  license file: "you can copy, modify, distribute, and use them for any purpose,
  including commercial, without asking permission or giving credit."
- Archive: https://github.com/btahir/open-lofi/releases/latest/download/openlofi.zip

Both files were taken out of that archive by byte range rather than by
downloading all 528 MB of it, and each was verified with `afinfo`: stereo,
48 kHz, about 180 kbps.

| File | Title | Category | Duration | Size |
| --- | --- | --- | --- | --- |
| `almost-floating.mp3` | Almost Floating | Ambient Drift & Dreamscapes | 3:22 | 4.3 MB |
| `deep-space-loop.mp3` | Deep Space Loop | Ambient Drift & Dreamscapes | 2:40 | 3.4 MB |

They are played as a rotation: when one finishes, the next starts, wrapping back
to the first. The order and the volume live in `lib/services/music_service.dart`;
swapping a track is dropping a file here and naming it there.

The other 19 ambient tracks in the collection (and 145 more in other categories)
are candidates if these two do not fit — the choice was made from titles and
categories, not by listening.
