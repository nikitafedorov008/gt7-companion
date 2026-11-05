# GT7 dealer UI references and proposal

Official references inspected 2026-11-05:

- [Used Cars manual](https://www.gran-turismo.com/us/gt7/manual/usedcar/01): [inventory](https://www.gran-turismo.com/images/c/i1PQvg8x57xaIdH.jpg), [vehicle dialog](https://www.gran-turismo.com/images/c/i1R958hVlHdWu.jpg).
- [Legend Cars manual](https://www.gran-turismo.com/us/gt7/manual/legendcar/01): [collection](https://www.gran-turismo.com/images/c/i1A1FX57SCRH0SH.jpg), [showroom](https://www.gran-turismo.com/images/c/i1r4no0rCGo84z.jpg).

Used original: pale grey dense photo-left cards, marque flag, model, PP capsule, drivetrain/aspiration, price bottom right, mileage over photo, sold-out red stamp, limited stock red label. Vehicle opens as a light dialog above a blurred inventory with big photo on left, facts on right, specification grid and actions below.

Legend original: dark Hagerty Collection, five tall catalogue columns, manufacturer logo, large year, car silhouette and blue hairline separators. Details become a dark warehouse/showroom composition with a large car and right-side specifications.

Companion adaptation: shared app navbar and safe areas retained; static local car artwork instead of an interactive 3D scene. Purchase becomes local Wishlist; Learn More uses the already bundled official localized history. Existing external price chart becomes a separate action instead of the primary card tap. Unknown mileage/colour/collection status never fabricated. Minimal local persistent wishlist and its existing page are included explicitly in the proposal, without account synchronization or notifications.

Code findings: both card onTap handlers currently launch a price PNG in a browser. Both `_formatMiles` helpers multiply estimateDays by 1000. Used PP displays `car.sort`, fixed stars show a made-up rating. These must be replaced with exact official catalogue joins and genuine unknown values. The existing wishlist page is a stub, so a real local toggle needs storage/list implementation rather than a decorative checkmark.

Prototype uses the real bundled 2026-11-04 inventory snapshot, local photo assets and exact RU specification strings. The prototype wishlist is a visual in-session demonstration, not the production storage implementation. Preview: http://127.0.0.1:8772/prototype.html; review controls at bottom switch Used/Legend. 1280px and 390px checks found no horizontal page/dialog overflow; all displayed images resolved. Card opening, close/Escape and toggle feedback verified. Flutter source behavior is unchanged pending approved GRACE spec/plan.
