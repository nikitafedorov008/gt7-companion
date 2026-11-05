# Проверка данных 2026-11-05

## Причины отказа ежедневных гонок

Предыдущая offline-проверка оставила тестовый entrypoint `.dart_tool/offline_cards.dart` в Mac-сборке. Его HttpOverrides специально запрещал исходящий HTTP, включая гонки. Запущено обычное `lib/main.dart`: сетевых ограничений в нём нет. Offline override не находится в исходниках приложения.

Дополнительно DG-Edge обновил сайт: `.event.daily` заменён на `.ev-card.ev-daily`, `.event-name` на `.ev-title` + `.ev-variant`, `.event-time` на `.ev-kicker`, маркер live — `ev-live`, URL теперь содержит slug и числовой ID. Текущие карточки скрывают видимые leaderboard totals/fastest time, архивные публикуют их в footer вместо прежних атрибутов. Парсер поддерживает обе разметки, сохраняет числовую identity, компоновку трассы, круги, шины, автомобиль, недели, live и архивную статистику. Отсутствующие upstream-значения не подменяются выдуманными.

Регрессия `test/dg_edge_redesign_test.dart` использует четыре реальные карточки нового сайта (три текущие и одна архивная) и ссылку пагинации. Прежние fixture-тесты сохранены.

## Доступность источников

8 live-тестов прошли (`--tags network --run-skipped`):

- DG-Edge: 12 гонок; GTSh: 6 карточек; общие ranking IDs найдены. В native Mac repository объединяет их в 12 гонок (6 пар).
- GT7Info: Used и Legendary, успешный свежий timestamp.
- GTDB: Used HTML и Legendary JSON, оба успешны после bundled snapshot.
- GTPlus: характеристики и свапы разбираются.
- Google CSV: данные деталей GT Auto разбираются.
- Apex: оглавление и вводная статья загружаются.
- Brand Central: локальный каталог читается; одна выбранная gallery module разрешается через живой официальный источник.

PSN-профиль не проверялся с реальной учётной записью: эта проверка публичных источников не подтверждает авторизованный API.

## Когда обновляются данные сейчас

| Данные | Фактическое поведение |
|---|---|
| Гонки | При создании виджета; кнопка повторного запроса при ошибке. Общего таймера нет. |
| Used / Legendary | При открытии; GTDB запрашивается снова, GT7Info после первого успеха пропускает запрос без forceRefresh. Снимок даёт cold offline данные. |
| GT Auto | При первом открытии, затем session cache; ручное forceRefresh доступно. |
| Apex | При первом открытии, смене языка или retry/forceRefresh; статьи кэшируются в сессии. |
| Brand Central, каталоги авто/трасс, локальные карточки | Статические bundled данные; обновляются генераторами и выпуском приложения. Галереи — при выборе авто с session cache. |
| PSN-профиль | При открытии и ручном обновлении (по исходникам, без проверки реального аккаунта). |
| Телеметрия | Непрерывный UDP-поток активного подключения; это не HTTP refresh. |

Итак, доступность публичных источников восстановлена/проверена, но периодическое обновление всех данных **не реализовано**. Пользователю предложена отдельная политика: гонки и инвентарь каждые 15 минут, GT Auto раз в час, обновление устаревших данных при resume, без очистки хороших данных при ошибке. Согласование этой реализации ожидается; без ответа она не добавлена.

## Команды и evidence

```sh
.fvm/flutter_sdk/bin/flutter test test/dg_edge_redesign_test.dart test/dg_edge_service_test.dart test/sport_repository_test.dart
.fvm/flutter_sdk/bin/flutter test --tags network --run-skipped test/live_markup_guard_test.dart test/live_data_sources_test.dart
```

22 deterministic tests passed; 8 live tests passed. Analyzer: no errors or warnings, existing informational lint items remain in the legacy model. Native Mac hot restart with normal entrypoint verified real A/B/C cards with class/car, tyre, laps and archived statistics. Screenshot: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/data-refresh/mac-daily-online.png`. Normal online Mac app left open. No commit/push.
