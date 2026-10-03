# CODE_STYLE.md — как устроен код GT7 Companion (авторские модули)

Документ описывает **фактический** стиль кода и вёрстки в модулях, которые писал автор:
ежедневные гонки, автосалоны (used/legendary), GT Auto, оболочка и навигация, домашний хаб,
вход через PSN, вишлист, а также слои моделей/репозиториев/сервисов этих модулей.

**Вне области:** телеметрия и профиль (их писал не автор) — они упоминаются только там, где важно
показать расхождение.

Составлено по чтению кода (не по догадкам): `lib/widgets/**` кроме телеметрии, `lib/pages/**`,
`lib/router/**`, `lib/dependency_injection/**`, `lib/theme/**`, `lib/models/**` кроме telemetry,
`lib/repositories/**`, `lib/services/**` кроме telemetry. Ссылки вида `файл:строка` — проверяемые.

---

## 0. Главное, что нужно знать до чтения правил

1. **В проекте две генерации кода, и они расходятся по цвету и типографике.**
   Старая: `lib/widgets/car_dealer/**`, `lib/models/{car_dealer,gt7info,gtdb}`, `lib/pages/home_page.dart`,
   `lib/widgets/adaptive_navbar.dart`. Новая: `lib/widgets/{daily_races,gt_auto}/**`,
   `lib/models/{gt7_stats,gt7_sport_*,dg_edge,gtsh_rank}`. Ниже везде указано, где правило «всегда»,
   где «обычно», а где генерации расходятся.
2. **`AGENTS.md` описывает проект неточно.** Он утверждает, что «BLoC — основной state management»,
   что «фичевые экраны лежат в `lib/pages/`» и что нужно «предпочитать `Theme.of(context)`».
   Фактически: BLoC в авторском коде не используется вообще, экраны-вертикали помечены `@RoutePage()`
   прямо в `lib/widgets/**`, а токены `gt7*` потребляет только телеметрия. При переносе этого документа
   в скиллы `AGENTS.md` надо поправить, иначе агент будет писать «по документации», а не «как в проекте».
3. **Правило важнее примера.** Старые файлы — источник легаси-приёмов (`Colors.grey[300]!`,
   `withAlpha`, `_buildXxx`), новые — источник канона. При правке старого файла держать его стиль,
   при создании нового — брать канон.

---

## A. Слои и ответственность

| Слой | Что там живёт | Чего там нет |
|---|---|---|
| `lib/services/` | один внешний источник на сервис: UDP, dg-edge, gtsh-rank, gt7info, GTDB, официальный API GT7. Сеть, парсинг, таймауты. | доменного слияния, виджетов |
| `lib/repositories/` | композиция нескольких источников + доменное слияние/дедуп/сортировка | HTTP-вызовов вообще (`sport_repository.dart:30` — только сервисы в конструкторе) |
| `lib/models/<источник>/` | модели по источнику данных (`gt7info/`, `gtdb/`, `dg_edge/`, `gtsh_rank/`, `car_dealer/`, `daily_races/`, `gt_auto/`) | сетевых вызовов |
| `lib/widgets/<вертикаль>/` | UI вертикали, **включая экраны** (`@RoutePage()`) | обращения к сети, бизнес-логики |
| `lib/pages/` | тонкие страницы-композиторы и модалки: хаб `home_page.dart`, `login_page.dart`, `wishlist_page.dart`, `empty_page.dart` | фичевых экранов вертикалей |
| `lib/blocs/` | только чужие (`profile`, `throttle_brake_graph`) | авторских блоков |

Правила:
- Данные тянутся из репозитория/сервиса **через провайдер**, а не создаются в виджете.
- Загрузка инициируется экраном один раз в `initState`, а не в `build`.
- Виджет не знает про HTTP, JSON и парсинг: он получает готовые доменные модели.

---

## B. Файлы, классы, имена

- **Вертикаль = папка.** Внутри пара: `<вертикаль>_display.dart` — экран, `<вертикаль>_grid_item.dart`
  — карточка-лист (`car_dealer/used/{used_car_display,used_car_grid_item}.dart`).
- **Имя класса = snake_case имени файла.** Расхождение встречается: `legendary_car_grid_item.dart:10`
  содержит `LegendaryCarCardItem` (файл `_grid_item`, класс `...CardItem`) — при новом файле имя
  файла и класса держать согласованными.
- **Несколько виджетов в одном файле — норма.** `daily_race_card.dart` держит `DailyRaceCard`,
  `_CardMetrics`, 6 приватных и 2 публичных виджета; `daily_races_display.dart` — экран и 7 приватных
  под баннером `// PRIVATE SECTION WIDGETS` (`:233`).
- **Публичный только тот виджет, который нужен другому файлу**; всё остальное — `_`.
- **Barrel/index-файлов нет** — соседей импортируют напрямую.
- **Приватные виджеты — существительное без суффиксов**: `_Hero`, `_HeaderBadge`, `_Title`,
  `_StatsFooter`, `_StatCell`, `_OptionRow`, `_HistogramRow`. Ни `...Widget`, ни `Custom...`, ни `My...`.
- Извлечённый в отдельный файл виджет — либо экран, либо переиспользуемый (`RaceFieldHistogram`).

---

## C. Конструкторы и параметры

```dart
const LegendaryCarCardItem({super.key, required this.car});          // legendary_car_grid_item.dart:13
const DailyRacesDisplay({super.key, this.showUpcoming = true});      // daily_races_display.dart:26
```

- Только **именованные** параметры; позиционных нет нигде.
- **Всегда `super.key`** и только первым (единственное исключение — `race_field_histogram.dart:15`,
  где `super.key` стоит последним; в новом коде так не делать).
- Никогда `Key? key`.
- **Данные — `required`; флаги отображения — необязательные с дефолтом.**
- **Листья принимают доменную модель, а не примитивы**: `final Car car;`, `final DailyRace race;`,
  `final GtAutoCounter counter;`. Примитивы — только в переиспользуемых мелочах
  (`_HistogramRow({required this.label, required this.count, ...})`).
- **Колбэки типизированные**: `final VoidCallback onTap;`, `final ValueChanged<GtAutoCounter> onSelect;`
  (`gt_auto_display.dart:161,113`). Никаких `Function` и `dynamic`.

---

## D. Состояние и данные в UI

- **Экран = `StatefulWidget`, лист = `StatelessWidget`.** Все ~20 карточек/листьев — без состояния.
- **Никакого BLoC в авторском коде.** Ни `BlocBuilder`, ни `BlocSelector`, ни `context.watch` в этих
  модулях не встречается (проверено grep; единственные совпадения — чужие profile/telemetry файлы).
- Данные: `Consumer<CarRepository>(builder: (context, repository, child) {...})`
  (`used_car_display.dart:38`), `Consumer<SportRepository>` (`daily_races_display.dart:76`).
- Загрузка — «выстрелил и забыл» из `initState`:
  ```dart
  Future.microtask(() { context.read<CarRepository>().fetchAllCars(); });   // used_car_display.dart:24
  WidgetsBinding.instance.addPostFrameCallback((_) { ... });                 // daily_races_display.dart:45
  ```
- **Источник правды о состоянии — репозиторий**, а не локальный флаг: в коде это даже записано
  комментарием — «Ignore local loading state and rely on the repository's `isLoading`»
  (`daily_races_display.dart:55`).
- **`setState` только на уровне экрана и только в обработчиках/загрузчиках**
  (`gt_auto_display.dart:33,42,57`; `daily_races_display.dart:57,66`). Внутри карточки — никогда.
- Локальное состояние — только UI-состояние (`GtAutoCounter? _counter;` — что выбрано).
- Варианты состояния выражаются парой `isLoading` + `error` + данные; sealed/copyWith-состояний нет.

---

## E. Dependency Injection

Единственная точка — `lib/dependency_injection/app_scope.dart`, `MultiProvider` **снаружи**
`MaterialApp.router` (`lib/app.dart:12`).

```dart
ChangeNotifierProvider(create: (context) => DgEdgeService()),                      // :51
ChangeNotifierProxyProvider2<GT7InfoService, GTDBService, CarRepository>(          // :104
  create: (context) => CarRepository(
    Provider.of<GT7InfoService>(context, listen: false),
    Provider.of<GTDBService>(context, listen: false),
  ),
  update: (context, a, b, repository) => repository ?? CarRepository(a, b),
),
```

Правила:
- Регистрации читаются **сверху вниз в порядке зависимостей**, и порядок поясняется комментарием,
  если он неочевиден: «It follows the telemetry service, so it needs it first» (`app_scope.dart:37`).
- Сервисы и репозитории — `ChangeNotifierProvider`; зависимые репозитории —
  `ChangeNotifierProxyProvider`/`ProxyProvider2` с идиомой
  `update: (context, dep, instance) => instance ?? Repo(dep)`.
- Эагерная инициализация — каскадом в `create`: `CarCatalog()..load()` (`:45`).
- Блоки (если появятся) — `Provider<TBloc>(create: ..., dispose: (context, bloc) => bloc.close())`
  (`:92-103`), а не `BlocProvider`.
- Внутри `create` — `Provider.of<T>(context, listen: false)`; в UI — `context.read<T>()` и `Consumer<T>`.
- **Чего не заводить:** `BlocProvider`, `RepositoryProvider`, `context.select`, service locator (`get_it`),
  page-level провайдеры. Ничего из этого в проекте нет.
- Утечки закрывать явно: подписка на `ChangeNotifier` — в конструкторе, отписка в `dispose()`
  (`track_repository.dart:14,40`).

---

## F. Роутинг

```dart
@AutoRouterConfig(replaceInRouteName: 'Screen|Page')
class AppRouter extends RootStackRouter {
  @override RouteType get defaultRouteType => RouteType.adaptive();
  @override List<AutoRouteGuard> get guards => [];
  @override List<AutoRoute> get routes => [ ... ];
}
```

- Экран помечается `@RoutePage()` над классом (`used_car_display.dart:11`), имя класса без суффикса
  `Page` → генерируется `UsedCarDisplayRoute`.
- Вложенность: корень `NestedWidgetRoute` (таб-шелл `AutoTabsRouter.pageView`, `nested_widget.dart:18`)
  → `HomeShellRoute` (`return AutoRouter()`, `home_shell.dart:16`) → `HomePage`/`UsedCarDisplay`/
  `LegendaryCarDisplay`/`GTAutoDisplay` (`app_router.dart:26-47`).
- Переход: только `context.router.push(const XRoute())` (`home_page.dart:24,28,32`).
- `Navigator` — только для модалки с результатом:
  `await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => const LoginPage()))`
  (`profile_page.dart:57`), `pop(true/false)` (`login_page.dart:423,501`).
- Гвардов, deep links, redirect нет и не требуется.

---

## G. Вёрстка

**Скелет экрана** (`used_car_display.dart:34-119`, `legendary_car_display.dart:43-129`):

```dart
Scaffold(
  extendBody: true, extendBodyBehindAppBar: true,
  appBar: null, bottomNavigationBar: null,          // хром всегда обнулён
  body: Consumer<Repo>(builder: (context, repository, child) {
    if (repository.isLoading) return const Center(child: CircularProgressIndicator());
    if (repository.errorMessage != null) return _ErrorBlock(...);
    return Column(children: [ шапка, const SizedBox(height: 16), Expanded(сетка) ]);
  }),
)
```

**Страница-хаб** — `SafeArea(bottom: false)` → `SingleChildScrollView(padding: EdgeInsets.fromLTRB(16,16,16,96))`
→ `Column(crossAxisAlignment: CrossAxisAlignment.start)` из готовых секций (`home_page.dart:81-93`).

**Адаптивность** — `LayoutBuilder` + порог:
- 600 — «узко/широко» (`used_car_display.dart:126`, `legendary_car_display.dart:144`);
- 600/800/900/1200 — число колонок сетки (`home_page.dart:98-99`, `used_car_display.dart:138-139`);
- сетка — `GridView.count`/`GridView.builder` с `SliverGridDelegateWithFixedCrossAxisCount`,
  `crossAxisSpacing: 12, mainAxisSpacing: 12` и подобранным `childAspectRatio`.

**Отступы** — `SizedBox(height: N)`, где N из набора {4, 6, 8, 10, 12, 14, 16, 20, 24};
доминируют 4/8/12/16/20. В новых файлах ещё `Column(spacing: 8.0)` и `Wrap(spacing:, runSpacing:)`.
`Padding` — для отступов; `Container` — только когда нужны decoration+padding+size вместе.

**Запрещено в этом проекте:** `Card`, `ListTile`, elevation/тени. Панель — это `Material`+`Ink`/`Container`
с волосяной рамкой.

**Карточка, канон (новый стиль)** — `daily_race_card.dart:60-75`, `gt_auto_display.dart:167-178`:

```dart
Material(
  color: ...,
  borderRadius: BorderRadius.circular(12),
  clipBehavior: Clip.antiAlias,
  child: InkWell(onTap: onTap, child: Ink(decoration: ..., child: ...)),
)
```

**Карточка, старый стиль** (`used_car_grid_item.dart:18-26`) — `GestureDetector` → `Container(margin:
EdgeInsets.all(8), decoration: BoxDecoration(color, borderRadius.circular(8), border: Border.all(...)))`.
При правке старой карточки стиль не менять, при новой — брать канон.

**Радиусы** (сложившийся словарь, централизации нет): 4–6 — бейдж/чип, 8 — плашка и мелкая карточка,
10–12 — карточка/панель, 50 — «пилюля».

**Плашка иконки:** 40×40 в строках (`gt_auto_counter_view.dart:99-107`), 52×52 в плитках
(`gt_auto_display.dart:183-195`), радиус 8–12, иконка 22–28. Цвет плашки варьируется: канон —
`secondary.withValues(alpha: 0.15)`, в старых файлах — `Colors.white10`/`Colors.grey[300]`.

**Строка списка:** плашка → `const SizedBox(width: 12)` → `Expanded(Column(имя, описание))` → trailing
(цена/шеврон).

**Заголовок секции:** UPPERCASE + `labelSmall/Medium.copyWith(letterSpacing, w700,
onSurface.withValues(alpha: 0.5))` (`daily_race_details_sheet.dart:396-400`, `gt_auto_counter_view.dart:256`).

**Пропорции — именованные константы с обоснованием замером:**

```dart
/// Width over height of the in-game card, measured off a 1080p capture
/// (578 × 645). The grid in [DailyRacesDisplay] shapes its tiles with it.
const double kDailyRaceCardAspectRatio = 578 / 645;      // daily_race_card.dart:20
const int _kHeroFlex = 519; const int _kBodyFlex = 287; const int _kFooterFlex = 194;   // :25-27
```

**Масштабирование типа от ширины с полом читаемости:**
`double _scaled(double ratio, double min) => (width * ratio).clamp(min, double.infinity);`
(`daily_race_card.dart:115`).

**Числовые колонки** — `fontFeatures: const [FontFeature.tabularFigures()]`
(`race_field_histogram.dart:147`, `daily_race_details_sheet.dart:363`).

---

## H. Цвет и типографика

- **Канон нового кода:** `final theme = Theme.of(context);` → `theme.colorScheme.*`, `theme.textTheme.*`
  (`.copyWith`), прозрачность — `withValues(alpha: …)`.
- **Легаси:** литеральные `TextStyle(fontSize: …, color: Colors.black87)` и `Colors.grey[300]!`
  (`used_car_grid_item.dart:25,76-97`). Не тиражировать.
- Замер по репозиторию: `withValues` — 188, `withOpacity` — 42, `withAlpha` — 4. Остатки сосредоточены
  в `lib/theme/gt7_theme.dart`, `lib/pages/{home,profile}_page.dart`, `car_dealer/**`, `adaptive_navbar.dart`,
  `telemetry/playstation_scanner_dialog.dart`.
- **Токены `lib/theme/gt7_theme.dart`** (`gt7Caption`, `gt7Digital`, `gt7PanelDecoration`, `GT7GraphColors`)
  — инструмент телеметрии; вне телеметрии не тянуть. Внешние модули работают с `ColorScheme`/`TextTheme`.
- Тёмная тема — единственная: `darkTheme`/`ThemeMode`/`themeMode` не заданы нигде.

---

## I. Состояния экрана

- **Загрузка.** Простой вариант — `const Center(child: CircularProgressIndicator())`
  (`legendary_car_display.dart:62`). Новый канон — настоящие скелеты: `Skeletonizer(enabled: true)`
  поверх 6 фейковых моделей `List<DailyRace>.generate(6, (_) => const DailyRace(trackName: 'Loading'))`
  с `Skeleton.keep` на шапке и подвале (`daily_races_display.dart:111-119,265,387`).
- **Пусто.** Секция — `if (values.isEmpty) return const SizedBox.shrink();`
  (`race_field_histogram.dart:33`); полноэкранно — панель с текстом и кнопкой обновления
  (`daily_races_display.dart:158-181`).
- **Ошибка.** Сегодня сосуществуют три вида: (а) центрированный `Icons.error_outline` 48 + заголовок +
  текст + `ElevatedButton.icon(..., fetchAllCars(forceRefresh: true))` (`used_car_display.dart:44-67`,
  `legendary_car_display.dart:65-92` — дублирован дословно); (б) инлайн-панель с `theme.colorScheme.error`
  и `IconButton` обновления (`daily_races_display.dart:78-108`); (в) локальная строка `_error`.
  **Канон: (б)** — инлайн-панель с `IconButton`; дублируемый центрированный блок не повторять.
- **Обновление — всегда `IconButton`**, `RefreshIndicator` не используется нигде.
- **Картинки.** Массово — `Image.network(..., errorBuilder: (_, __, ___) => const SizedBox.shrink())`
  (`daily_race_card.dart:158,188`). Тяжёлая графика машин — `ExtendedImage.network` + `loadStateChanged`
  с явными placeholder/failed (`used_car_grid_item.dart:293-308`), а для GTDB — AVIF поверх стандартного
  превью GT7 с намеренно пустым `errorBuilder`, чтобы не мигала ошибка (`:233-291`).

---

## J. Модели

- **Ручной JSON, кодогенерации нет** (freezed/json_serializable в pubspec есть, но используются только
  чужими блоками). Маппинг — `factory X.fromJson(Map<String, dynamic> json)`; 22 такие фабрики на 16
  классов. Варианты по источнику: `GTDBCar.fromUsedCarJson` / `fromLegendCarJson` (`gtdb_data.dart:65,104`).
- **`final`-поля + один именованный конструктор** со всеми параметрами; `required` для обязательного,
  остальное — именованные optional с дефолтами (`car.dart:26-46`).
- В новом слое конструктор `const` (`daily_race.dart:49`, `dg_edge_daily_race.dart:435`); в старом —
  не const (легаси).
- **Конверт ответа разворачивается в модели**: `final r = json['result'] as Map<String, dynamic>? ?? json;`
  (`gt7_stats.dart:64`) — модель принимает и обёрнутый, и плоский ответ.
- **Null-safety, новый стиль**: `(json['race'] as num?)?.toInt() ?? 0`, общий хелпер
  `static int _int(Object? v, {int fallback = 0})` (`gt7_stats.dart:85`), `fallback: -1` для «неизвестно».
  Старый стиль — `json['carid'] ?? ''` без каста.
- **Презентационные геттеры живут в модели**: `displayPrice`, `isSoldOut`, `statusText`, `carImageUrl`
  с приоритетами, объяснёнными комментариями (`car.dart:50-98`).
- **Enum + extension**: enum без полей, логика в `extension X on Enum` со `static parse(String?)`,
  неизвестное → `null`, а не «правдоподобная догадка» (`dg_edge_daily_race.dart:19-320`, `race_status.dart:14`).
- **`==`/`hashCode` не переопределяются нигде**; `copyWith` — ровно один (`gt7_user_stats.dart:74`).
  `toString()` — почти у всех, формат `'ClassName(field: $value)'`.
- `@immutable` ставится явно (`daily_race.dart:11`, `gt_auto_catalog.dart:13`).
- Бизнес-логики в моделях нет — только презентационные геттеры и мелкие форматтеры
  (`_formatCredits`, `formatLapTime`).

---

## K. Репозитории и сервисы

**Репозиторий:**

```dart
abstract class SportRepository extends ChangeNotifier {      // :11
  List<DailyRace> get dailyRaces;
  bool get isLoading;
  String? get error;
  Future<void> fetchDailyRaces({bool forceRefresh = false});
}
class SportRepositoryImpl extends SportRepository { ... }    // :22
```

- Публичный API — геттеры `data` / `isLoading` / `error` + `Future<void> fetchX({bool forceRefresh = false})`.
- **Исключения наружу не поднимаются**: `catch (e) { _errorMessage = 'Error loading …: $e'; }` +
  `finally { _isLoading = false; notifyListeners(); }` (`car_repository.dart:97`, `sport_repository.dart:92-95`).
- **Частичный отказ не роняет результат**: два независимых `try` внутри одного, ошибки копятся в
  `dgError`/`gtshError`, и общий `_error` ставится только если обе ветки пусты
  (`sport_repository.dart:60-88`).
- HTTP и JSON-декодирование — в сервисах; репозиторий сливает, дедуплицирует и сортирует.
- Логирование — `debugPrint('ИмяКласса: что произошло $данные')`.
- Порядок членов: зависимости → приватное состояние → геттеры → конструктор → публичные методы →
  приватные хелперы → фильтры-геттеры в конце.
- Кэш — ручные булевы флаги (`_isLoaded`) и guard `if (!forceRefresh && _data != null) return;`;
  TTL нет.

**Сервис:**

- Один внешний источник; каркас — `_isLoading` + `_error` + геттеры + `Future<T> fetchX({bool forceRefresh})`
  (`dg_edge_service.dart:34-64`).
- Сетевой вызов: `_setLoading(true)` → `if (resp.statusCode != 200) throw Exception('HTTP ${resp.statusCode}')`
  → `catch (e) { _error = '…: $e'; rethrow; }` → `finally { _setLoading(false); }`. `rethrow` — только
  в скрейперах, их ловит репозиторий.
- **Клиент инжектируется с дефолтом**: `DgEdgeService({http.Client? httpClient}) : _http = httpClient ?? http.Client();`
  (`dg_edge_service.dart:31`).
- Таймауты и вежливость — константы класса: `static const Duration _timeout = Duration(seconds: 12);`,
  `static const Duration _crawlDelay = Duration(milliseconds: 350); // be polite` (`dg_edge_service.dart:20-21`).
- Заголовки — `_defaultHeaders()`/`_defaultJsonHeaders()` с осмысленным User-Agent.
- Платформенные развилки — `switch (defaultTargetPlatform)` с деградацией и записью в лог
  (`gt7_auth_service.dart:121-145`), а не `Platform.isX` напрямую (кроме `NetworkScanner`).
- Секреты не попадают в лог: маскирование (`gt7_auth_trace.dart:104`, `gt7_auth_service.dart:330`).

---

## L. Порядок, импорты, комментарии

- **Порядок членов виджета:** поля → конструктор → статики → `build` → приватные методы
  (`_buildStatusBadge` → `_getCarImageUrl` → `_buildImageWidget` → `_launchPriceHistory` → `_formatMiles`,
  `legendary_car_grid_item.dart:11-324`).
- **Порядок членов страницы:** `static const`-конфиг → поля → геттеры → `initState`/`dispose` →
  приватные хелперы под баннерами `// ----` → **`build` последним** (`login_page.dart:34-106,492`).
- Приватные виджеты — **после** класса страницы и **в порядке появления в дереве**
  (`home_page.dart:245`; `daily_race_card.dart`: `_Hero`, `_HeaderBadge`, `_GridGlyph`, `_Title`, …).
- Импорты: `dart:` → пустая строка → `package:` (flutter первым) → пустая строка → относительные `../`.
  Внутри групп алфавит не соблюдается — не критично, но в новых файлах лучше упорядочить.
- **Документирующие `///`** — на классах и нетривиальных геттерах; объясняют **почему** и **откуда взято
  число** (примеры: измеренная пропорция карточки, «DG-Edge says "Grand Valley" where GTSh says
  "Grand Valley - Highway 1"», «an unknown code yields null rather than a plausible-looking wrong letter»).
- Inline `//` — допускаются на русском (`home_page.dart:72`, `used_car_grid_item.dart:234-288`),
  хотя доккомментарии нового слоя английские. Если сводить к одному языку — сводить доккомментарии
  к английскому, inline оставить как есть.
- Файловый баннер `// имя_файла.dart` — привычка только `lib/widgets/car_dealer/**`; в новых файлах
  не обязателен.
- Пометки `// NEW:` и закомментированные блоки — легаси, не тиражировать.

---

## M. Найденные долги (то, что стоит поправить при касании)

| Что | Где | Почему это долг |
|---|---|---|
| `Colors.grey.withAlpha(280)` | `used_car_grid_item.dart:23` | аргумент вне 0–255, в debug-сборке это assert; рядом `withAlpha(240)` в `used_car_display.dart:35` |
| `_buildStatusBadge` побайтово дважды | `used_car_grid_item.dart:188`, `legendary_car_grid_item.dart:191` | копипаста — вынести в общий виджет |
| Блок ошибки дублирован дословно | `used_car_display.dart:44-67`, `legendary_car_display.dart:65-92` | две копии; канон — инлайн-панель |
| `print(configuration.size!.height)` внутри `paint` | `legendary_car_grid_item.dart:363` | отладочный вывод в горячем пути |
| Закомментированные блоки | `legendary_car_grid_item.dart:23-26`, `adaptive_navbar.dart:192-194,211-214,279-281,298-301` | мёртвый код |
| `statusText`/`carImageUrl`-логика расходится по трём файлам legendary/used | `car_dealer/**` | дублирование доменной логики |
| Три сервиса игнорируют инъекцию `http.Client` | `gt7info_service.dart:32`, `gtdb_service.dart:93`, `gt7_api_service.dart:71` | нельзя подменить в тестах |
| `_lastUpdated` пишется, но нигде не читается | `gt7info_service.dart:12,37`, `gtdb_service.dart:16,70` | мёртвое поле: TTL кэша так и не появился |
| `ProfileRepositoryImpl extends ProfileRepository with ChangeNotifier` | `profile_repository.dart:15` | расходится с каноном `abstract class X extends ChangeNotifier` |
| `settings_service.dart` — пустой файл | `lib/services/settings_service.dart` | мусор |
| `print` в легаси-сервисах | `udp_service.dart:37,74,84,132` | вместо `debugPrint` |

---

## N. Рецепты

### Новый экран-вертикаль

1. Папка `lib/widgets/<вертикаль>/`, файлы `<вертикаль>_display.dart` и `<вертикаль>_<leaf>.dart`.
2. Экран: `@RoutePage()` + `StatefulWidget`, `const XDisplay({super.key})`.
3. В `initState` — `Future.microtask(() => context.read<Repo>().fetchX());`.
4. `Scaffold(extendBody: true, extendBodyBehindAppBar: true, appBar: null, bottomNavigationBar: null)`.
5. Тело — `Consumer<Repo>` с ветками `isLoading` → скелет/спиннер, `error` → инлайн-панель, данные → `Column`.
6. Шапка — `Padding(EdgeInsets.only(left: 16, right: 16, top: 16))`, далее `SizedBox(height: 16)`,
   затем `Expanded(GridView.builder|ListView.builder)` с `padding: EdgeInsets.all(8)`.
7. Адаптив — `LayoutBuilder`: `< 600` список, дальше сетка 2/3/4 колонки по 800/1200, зазоры 12.
8. Карточка — `Material(borderRadius: 12, clipBehavior: Clip.antiAlias)` → `InkWell` → `Ink`.
9. Цвета/шрифты — только `theme.colorScheme`/`theme.textTheme` + `withValues(alpha:)`.
10. Зарегистрировать экран в `lib/router/app_router.dart` внутри нужной ветки и, если у него есть хаб-плитка, добавить `_AppTile` в `home_page.dart`.

### Новая карточка

`StatelessWidget`, единственный `required`-параметр — доменная модель, `super.key` первым;
`build` начинается с вычисления локальных значений; дерево разбито комментариями-секциями;
мелкие части — приватные классы-существительные в том же файле ниже; форматтеры — приватные методы;
картинка — с `errorBuilder`/`loadStateChanged` и явным fallback.

### Новый источник данных

1. Модель в `lib/models/<источник>/` с `factory X.fromJson`, `final`-полями и презентационными геттерами.
2. Сервис `lib/services/<источник>_service.dart`: `extends ChangeNotifier`, `_isLoading`/`_error`,
   инжектируемый `http.Client?`, константы таймаута, `debugPrint` с префиксом класса, `rethrow` при скрейпинге.
3. Репозиторий `lib/repositories/<домен>_repository.dart`: `abstract class X extends ChangeNotifier` +
   `XImpl`, слияние источников, частичные ошибки, `_error` вместо исключений.
4. Регистрация в `AppScope` в порядке зависимостей, с комментарием, если порядок неочевиден.
5. Экран по рецепту выше.

### Новый enum-парсер

`enum` без полей + `extension X on Enum` со `static X? parse(String?)`; switch по вариантам;
неизвестное → `null`; маппинги «код → значение» — `static const Map<...>` с пометкой, чем подтверждено.

---

## O. Как из этого сделать скиллы

Документ разбивается на пять скиллов (формат как у существующих `.agents/skills/**/SKILL.md`:
frontmatter `name` + `description`, дальше инструкции):

| Скилл | Что несёт | Источник |
|---|---|---|
| `gt7-project-map` | слои, где что лежит, что вне области, поправки к `AGENTS.md` | §0, A |
| `gt7-widget-style` | файлы/классы/параметры, состояние, вёрстка, цвет, состояния экрана | §B, C, D, G, H, I |
| `gt7-di-and-routing` | `AppScope`, порядок провайдеров, auto_route, переходы | §E, F |
| `gt7-data-layer` | модели, репозитории, сервисы, enum-парсеры | §J, K |
| `gt7-screen-recipe` | чеклисты «новый экран / карточка / источник» + список анти-паттернов для ревью | §N, M |

Порядок действий при переносе: сначала `gt7-project-map` (чтобы агент не верил устаревшему `AGENTS.md`),
потом `gt7-widget-style` и `gt7-data-layer`, затем рецепты. Если проект переходит на GRACE — эти же
разделы ложатся в контракты модулей (UI-модуль, data-модуль) и в `verification-plan.xml` как правила
проверки вёрстки/слоёв.
