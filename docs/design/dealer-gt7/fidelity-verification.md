# Card fidelity implementation — 2026-11-05

Implemented the user-approved fidelity audit in C-DEALER-CARD-FIDELITY.

## Changes against reference
- Used desktop card width/height calibrated to 2.86 (minimum 140 logical points for narrow/adapted layouts), equal photo/text halves and contained photographs. PP and italic drivetrain/aspiration sit on a single distributed row. The stock area reserves equal height so normal and limited cards retain common anchors. Small Cr. prefix, larger bold credit amount, outlined mileage icon and unknown-value dash; sold photos darken and retain red stamp.
- Hagerty uses corner marks rather than complete rectangular borders, reference-width columns and normalized vertical anchors. Logo/model/year/silhouette/rules/price follow the saved official screenshot's composition. Regular weight price, small credit prefix, explicit unknown mileage; limited stock includes a warning triangle. Desktop stays horizontal; phone stays vertical with pull-to-refresh.
- Feature typography uses Arial with platform fallback, tighter tracking and measured weights. This is a close available substitute, not a claim to ship the original game's font file.
- No fake collection-book icon, ownership, mileage, vehicle body colour, price trend or PSN actions. Existing data and assets are retained; some manufacturer logo versions and fallback silhouettes differ from actual GT7 inventory art. These asset/data differences prevent a truthful claim of literal pixel identity.

## Verification
- 71 targeted tests passed: /tmp/fidelity-tests.log. Exact desktop Used ratio, price-prefix hierarchy, corner painting, long-name limited-stock card at 140 points, RU/EN, text 1.0/1.5, 390/820/1280 layouts, horizontal scroll, phone pull-to-refresh, real dialogs, scroll restore, persistent wishlist and exact metadata joins.
- Changed-code analyzer clean: /tmp/fidelity-analyze.log.
- Native Mac inspected through actual CUA window against used-grid.jpg and legend-grid.jpg. Native phone inspected and interacted with through visible IAB serve-sim mirror. Both references reside in docs/design/dealer-gt7/references/.
- Evidence folder: /Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/dealer-gt7/native/ . Images: used-fidelity-mac.png, legend-fidelity-mac.png, used-fidelity-phone.png, legend-fidelity-phone.png. The phone evidence includes the final shared stock anchor and photo-ink refinements; Mac screenshot of Used precedes these two small refinements. The final ordinary Mac build contains all source refinements and is inspected before handoff.
- Marionette had an approval-review timeout; native inspection continued through CUA. No product behavior was inferred from that failed automation request.
- Phone app and scoped mirror helper stopped after visible inspection. Ordinary online lib/main.dart launched on Mac; no mock preferences or networking overrides.

## Remaining scope boundaries
Portrait is a responsive adaptation because GT7 has no original portrait screen. Typography/assets described above are explicit remaining differences from the literal original. No commit or push. Final apply/archive explicitly confirmed by the user on 2026-11-05; spec and plan marked applied and bundle archived under .grace/changes/archive/C-DEALER-CARD-FIDELITY.
