# Dealer country enrichment

A replay of the public GT7Info/GTDB responses captured on 2026-11-05 through the
production parsers and repository found 24 missing countries in 67 unified rows.
All 24 were GTDB-only Used rows. Their exact official catalogue records contained
countries; no name-based country inference was needed.

CarRepository now waits for the bundled DealerCatalogRepository and fills only
missing/unknown countries after inventory merging. This order matters because
Legendary GTDB IDs are internal IDs; the matched GT7 ID must be used instead.
Existing valid source countries and all sale/artwork fields are retained. Unknown
IDs and official `Other` remain unknown. Rotated-out wishlist records receive the
same exact-ID country lookup.

The same captured responses now produce 0 missing countries out of the same 67
rows. A fresh native run showed French, German and Japanese flags on previously
unknown rows. Six missing flags (gb/se/at/cz/cn/kr, 1470 bytes combined) were added
through the local artwork updater so all known official catalogue countries have
bundled flag assets. Final Volvo flag visual recheck was unavailable because the
Mac locked; all flag assets are loaded by the regression test.

Validation: 84 targeted tests pass (including exact-ID/unknown-ID, offline merge,
source-country preservation, wishlist, missing catalogue, bundled flags, artwork
updater and responsive dealer UI); changed-file analyzer clean.
