# Regional fallback studio background — 2026-11-05
Used cards and their vehicle dialog decorate official transparent thumbnails with a
vertical regional studio gradient: Europe warm stone, Asia cool grey, Americas
sandstone, unknown neutral grey. The darker floor begins around the wheel line.
Decoration follows the actually selected image (including failed-primary fallback),
while photographs keep their original background. Legendary styling is unchanged.
Validation: local artwork fallback regression, three-width card layouts and vehicle
dialog tests; native Mac grid and Ferrari dialog visually inspected.

Follow-up: floor transition raised to 36–67% and floor darkened; a white Used
SVG watermark appears at top left only on decorated thumbnails, including runtime
fallbacks. Photographs do not receive a duplicate watermark.

## Reconstructed photographic backplates
The approved European preview and two matching restorations now replace the
regional gradient for known countries in Used cards and their vehicle dialog.
These are AI-restored backgrounds, not extracted original game assets. Car,
shadow and baked-in labels were removed from the bundled GTDB dealer photographs.
The car thumbnail, white Used watermark and mileage remain separate UI layers.
Unknown countries keep the neutral gradient; original photos are unchanged.

Bundled WebP assets (quality 90): Europe 378444 B, Asia 260212 B, America 464200 B;
combined 1102856 B. All are 1559x1009, displayed with BoxFit.cover.
Sources: GTDB used image IDs 2bb0b5f3-7981-4303-dfda-ee89cfe06600 (FIAT),
e6ddabdd-5168-40a7-a5ce-4ff77fdf8800 (Honda),
a05f8e11-f28e-4bdb-f77d-d6488be71700 (Pontiac).
Validation: 47 artwork/card/dialog tests, widths 390/820/1280; targeted analyzer
clean; native Mac Used grid inspected with Ferrari/Citroën and original FIAT photos.


## Low-camera variants — 2026-11-05
The requested v2 backplates use a lower, near-horizontal camera matching the
side-dominant official thumbnail angle. Europe/Asia show less foreground floor;
America uses a low industrial wall rather than a high-view parking sweep.
Original backplates remain as siblings for comparison; runtime uses `-v2.webp`.
Thumbnail proportions/contain sizing remain intact: a full-catalogue alpha-bound
check found that global 1.12 enlargement would crop 38 thumbnails horizontally.
V2 WebP total: 749194 bytes. 47 targeted tests pass and changed source analysis is
clean. Native Mac Used inspected with the new European backplate.
