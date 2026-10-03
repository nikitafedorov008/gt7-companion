---
name: gt7-screen-recipe
description: Step-by-step recipes for adding a screen, a card, a data source or an enum parser in GT7 Companion, plus the review checklist of known anti-patterns. Use when implementing a new feature screen or reviewing a diff in this app.
---

# GT7 Companion — recipes and review checklist

Evidence: [`docs/CODE_STYLE.md`](../../../docs/CODE_STYLE.md) sections M–N.
Read `gt7-project-map`, `gt7-widget-style` and `gt7-data-layer` first.

## New vertical screen

1. Create `lib/widgets/<vertical>/` with `<vertical>_display.dart` (screen) and `<vertical>_<leaf>.dart` (card).
2. Screen: `@RoutePage()` on a `StatefulWidget`, `const XDisplay({super.key})`.
3. In `initState`: `Future.microtask(() => context.read<Repo>().fetchX());`.
4. `Scaffold(extendBody: true, extendBodyBehindAppBar: true, appBar: null, bottomNavigationBar: null)`.
5. Body: `Consumer<Repo>` with three branches — loading, error (inline panel + refresh `IconButton`), data.
6. Data branch: header `Padding(left: 16, right: 16, top: 16)` → `SizedBox(height: 16)` →
   `Expanded(GridView.builder | ListView.builder)` with `padding: EdgeInsets.all(8)`.
7. Adapt with `LayoutBuilder`: `< 600` = list, then grid with 2/3/4 columns at 800/1200, gaps 12.
8. Card shell: `Material(borderRadius: BorderRadius.circular(12), clipBehavior: Clip.antiAlias)` → `InkWell` → `Ink`.
9. Colours and text only from `Theme.of(context)` + `withValues(alpha:)`.
10. Register the route in `lib/router/app_router.dart` inside the right branch; add an `_AppTile` on the hub
    in `lib/pages/home_page.dart` if it belongs there.

## New card

`StatelessWidget`; one `required` domain model; `super.key` first; `build` starts by computing local values;
the tree is split by section comments; small parts become private noun-classes lower in the same file;
formatters are private methods; images always have an explicit placeholder and fallback.

## New data source

1. Model in `lib/models/<source>/` with `factory X.fromJson` and presentation getters.
2. Service `lib/services/<source>_service.dart`: `extends ChangeNotifier`, `_isLoading`/`_error`, injected
   `http.Client?`, timeout constant, `debugPrint` prefixed with the class name, `rethrow` when scraping.
3. Repository `lib/repositories/<domain>_repository.dart`: `abstract class X extends ChangeNotifier` + `XImpl`,
   merges sources, tolerates partial failure, keeps errors in `_error`.
4. Register in `AppScope` in dependency order with an explanatory comment if the order matters.
5. Build the screen with the recipe above.

## New enum parser

`enum` without fields + `extension X on Enum` with `static X? parse(String?)`; a `switch` over the variants;
unknown input returns `null`; code→value tables are `static const Map<...>` with a note about what confirmed them.

## Review checklist — do not ship these

- `withAlpha(280)`-style out-of-range alpha, `withOpacity`/`withAlpha` in new code — use `withValues(alpha:)`.
- A copy-pasted `_buildStatusBadge` or a duplicated error block; extract a widget instead
  (`used_car_grid_item.dart` and `legendary_car_grid_item.dart` already carry byte-identical copies).
- A debug `print` in a hot path, commented-out decoration/colorFilter blocks, `// NEW:` markers.
- A new hardcoded `TextStyle`/`Colors.grey[300]!`/`Color(0xFF…)` where a token or `theme.colorScheme` exists.
- `Card`, `ListTile`, elevation, `RefreshIndicator`.
- `setState` inside a leaf widget; local loading flags that duplicate the repository's.
- `BlocProvider`, `RepositoryProvider`, `context.select`, a service locator, page-level providers.
- Static `http.get`/`http.post` in a new service instead of an injected client.
- A screen placed in `lib/pages/` when it is a vertical; a file in `lib/widgets/` that talks to HTTP.
- `Key? key`, positional constructor parameters, untyped `Function` callbacks.
- Restyling telemetry or profile files, or importing `gt7*` theme helpers outside telemetry.
- A model that guesses an unknown enum code instead of returning `null`; a model with `==`/`hashCode`.
