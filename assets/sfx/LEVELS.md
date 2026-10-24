# Interface levels

Generate: `python3 tools/generate_menu_sfx.py`.
All eight files are RMS-normalised to -24.00 dBFS over their own duration.
Each Sfx.gain is 0.8 (-1.94 dB), giving -25.94 dBFS at the default volume.
Peaks remain below -6 dBFS before channel gain. Attack is 6ms; release 25ms.
The music bed peaks in mean level at -39.5 dBFS (track mean -19.5, gain 0.1),
leaving over 13dB mean separation. No normalisation to 0dB peaks.

The asset tests read actual PCM samples and check level and clipping headroom;
the mix test checks channel balance against the shipped music rotation.
