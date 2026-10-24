# Soft menu sound bank

Eight original synthesised cues, inspired by the restrained, tonal character of
Gran Turismo menu feedback. No audio sampled from Gran Turismo or third-party
sound packs. Replaces Kenney Interface Sounds throughout the app.

Reproduce with `python3 tools/generate_menu_sfx.py` (Python standard library).
The source defines every note, envelope and partial. Rounded sine tones with
quiet piano-like harmonics, a 6ms attack and a 25ms release avoid sharp clicks,
noise bursts and abrasive buzzing. Navigation rises, back descends, confirmation
resolves upwards, error uses a gentle low descending pair.

Format: 44.1kHz mono 16-bit PCM WAV, generated directly (no codec conversion).
