# Interface sound effects

All eight effects come from Kenney's **Interface Sounds** pack (version 1.0, 2020).
The pack is released under **Creative Commons Zero (CC0)**: its own `License.txt`
states the content is "free to use in personal, educational and commercial
projects" and that crediting is not mandatory. We credit anyway.

- Pack: https://kenney.nl/assets/interface-sounds
- License: https://creativecommons.org/publicdomain/zero/1.0/
- Author: Kenney — https://kenney.nl

| File here | Original in the pack | Used for |
| --- | --- | --- |
| `tap.ogg` | `click_001.ogg` | a press that does not navigate |
| `navigate.ogg` | `open_001.ogg` | a route push |
| `back.ogg` | `back_001.ogg` | a route pop |
| `open.ogg` | `open_002.ogg` | a bottom sheet opening |
| `close.ogg` | `close_001.ogg` | a bottom sheet closing |
| `toggle.ogg` | `toggle_001.ogg` | switching a setting |
| `confirm.ogg` | `confirmation_001.ogg` | an action that succeeded |
| `error.ogg` | `error_001.ogg` | a failure state appearing |

Replacing any file with another CC0 sound needs no code change: the mapping from
each effect to its asset lives in `lib/models/sfx.dart`.

Files are kept in OGG Vorbis, the smallest format the pack ships and one the
audioplayers plugin plays on every platform this app targets. Each effect is
under 15 KB, so the whole set costs about 64 KB.
