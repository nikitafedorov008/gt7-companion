---
name: gt7-widget-style
description: How widgets are written in GT7 Companion - file and class naming, constructor shape, state, layout skeleton, spacing, cards, colour and typography, loading/empty/error states. Use when creating or editing any widget, card, screen section or list row in this app.
---

# GT7 Companion — widget style

Evidence for every rule: [`docs/CODE_STYLE.md`](../../../docs/CODE_STYLE.md) sections B–D, G–I.
Scope: author-written modules only (not telemetry, not profile — see `gt7-project-map`).

## Files, classes, names

- A vertical is a folder with a screen file and a leaf file: `<vertical>_display.dart`, `<vertical>_grid_item.dart`.
- One class per file normally; several related widgets per file is fine. Private widgets sit in the same file
  under the tree order they appear in.
- Public only when another file needs it; everything else is `_`-prefixed.
- Private widget names are bare nouns: `_Hero`, `_HeaderBadge`, `_Title`, `_StatsFooter`, `_StatCell`, `_OptionRow`.
  No `...Widget`, `Custom...`, `My...` suffixes.
- No barrel/index files — import siblings directly.

## Constructors

```dart
const LegendaryCarCardItem({super.key, required this.car});
const DailyRacesDisplay({super.key, this.showUpcoming = true});
```

- Named parameters only; `super.key` first; never `Key? key`.
- Data is `required`; display flags are optional with defaults.
- Leaves take domain models (`final Car car`), not primitives. Primitives are for generic reusables.
- Callbacks are typed: `VoidCallback onTap`, `ValueChanged<GtAutoCounter> onSelect`.

## State and data

- Screen = `StatefulWidget`, leaves = `StatelessWidget` (never `setState` inside a card or list item).
- Read data with `Consumer<Repo>` / `context.read<Repo>()`; trigger the fetch once from `initState`
  (`Future.microtask` or `addPostFrameCallback`) and forget it.
- Trust the repository's flags (`isLoading`, `error`) — do not mirror them in local state.
- No BLoC in these modules.

## Screen skeleton

```dart
Scaffold(
  extendBody: true, extendBodyBehindAppBar: true,
  appBar: null, bottomNavigationBar: null,
  body: Consumer<Repo>(builder: (context, repository, child) {
    if (repository.isLoading) return const Center(child: CircularProgressIndicator());
    if (repository.errorMessage != null) return _ErrorPanel(...);
    return Column(children: [ header, const SizedBox(height: 16), Expanded(gridOrList) ]);
  }),
)
```

Heading padding 16; list/grid `padding: EdgeInsets.all(8)`; grid gaps 12.

## Layout rules

- Responsiveness with `LayoutBuilder`: 600 = narrow/wide; 600/800/900/1200 = column count.
- Spacing is `const SizedBox(height|width: N)` with N from {4, 6, 8, 10, 12, 14, 16, 20, 24}; 4/8/12/16/20 dominate.
  Newer files may use `Column(spacing: 8.0)` and `Wrap(spacing:, runSpacing:)`.
- `Padding` for spacing; `Container` only when decoration + padding + size are needed together.
- **Never** `Card`, `ListTile`, elevation or shadows. Panels are `Material`/`Container` with a hairline border.
- Card canon: `Material(borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias)` → `InkWell` → `Ink`.
- Radius vocabulary: 4–6 badge/chip, 8 plate, 10–12 card/panel.
- Icon plate: 40×40 in rows, 52×52 in tiles, icon 22–28, `secondary.withValues(alpha: 0.15)`.
- List row: plate → `SizedBox(width: 12)` → `Expanded(Column(name, description))` → optional trailing value.
- Section header: `title.toUpperCase()` + `labelSmall/Medium.copyWith(letterSpacing, FontWeight.w700,
  color: onSurface.withValues(alpha: 0.5))`.
- Aspect ratios are named constants justified by a measured capture (`kDailyRaceCardAspectRatio = 578 / 645`).
- Width-driven type scaling gets a legibility floor: `(width * ratio).clamp(min, double.infinity)`.
- Numeric columns use `fontFeatures: const [FontFeature.tabularFigures()]`.

## Colour and typography

- Start `build` with `final theme = Theme.of(context);`, then use `theme.colorScheme.*` and `theme.textTheme.*`
  (with `.copyWith`), transparencies via `withValues(alpha: …)`.
- Do not add literal `TextStyle(fontSize: …)`, `Colors.grey[300]!`, `withOpacity` or `withAlpha` in new code.
- `gt7*` helpers from `lib/theme/gt7_theme.dart` belong to telemetry — do not use them in verticals.

## States

- Loading: simple `CircularProgressIndicator`, or the newer `Skeletonizer(enabled: true)` over ~6 fake models
  with `Skeleton.keep` on header/footer.
- Empty: `SizedBox.shrink()` for a section; a text panel with a refresh button for a whole screen.
- Error: inline panel tinted with `theme.colorScheme.error` plus a refresh `IconButton`. Do not copy the old
  centred `Icons.error_outline` block with `ElevatedButton.icon` that exists in two car-dealer screens.
- Refresh is always an `IconButton` — `RefreshIndicator` is not used in this project.
- Images: `Image.network(..., errorBuilder: (_, __, ___) => const SizedBox.shrink())`; heavy car art uses
  `ExtendedImage.network` + `loadStateChanged` with explicit placeholder/fallback.

## Member order inside a class

fields → constructor → statics → `build` → private helpers (data helpers last).
Newer code prefers extracted private widget classes over `_buildXxx()` methods.

## Language

UI copy is English and game-styled (uppercase labels). `///` doc comments explain **why** and where a number
came from; inline `//` may be Russian. Do not add `// NEW:` markers or commented-out code blocks.
