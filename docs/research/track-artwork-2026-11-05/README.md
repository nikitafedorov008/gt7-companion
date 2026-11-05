# Локальная графика трасс

Собрано 2026-11-05 из публичного каталога DG-Edge и схем, выбранных на странице ежедневных гонок GTSh.

- 42 локации, 124 конфигурации DG-Edge: фото, логотип и схема у каждой.
- 372 DG-Edge URL + 5 уникальных GTSh course URL = 377 исходных адресов.
- После SHA-256 дедупликации: **211 файлов, 30 668 808 байт (29,25 MiB)**.
- Все файлы прошли проверку размера, хеша и декодирование Pillow. Ошибок обнаружения/скачивания нет.
- Все 111 записей существующего локального каталога имеют соответствие источнику: 107 по authoritative externalId, 4 по явно проверенным supplementary ID (Eiger, reverse, Yas Marina, Gilles-Villeneuve). Метаданные/алгоритм определения трассы по телеметрии не изменялись.
- Пользовательские фото, аватары, галереи автомобилей, реклама и session/CSRF поля не входят в набор. Разрешены только `/images/tracks/<id>/…` DG-Edge и `/images/course/<id>.png` GTSh.

## Как подключено

`assets/track_images/manifest.json` содержит canonical URL, SHA-256, размер, тип и HTTP validators. `assets/tracks/artwork_catalogue.json` хранит только опубликованные конфигурации и их image descriptors. Генератор строит `lib/models/daily_races/track_image_assets.dart`: URL→asset (включая aliases размеров того же изображения) и track ID→canonical role URL. Для отображения хранится один исходник высокого разрешения; Flutter декодирует его с cacheWidth=1024, не создавая полноразмерную texture на каждую карточку.

`TrackArtwork` показывает локальные изображения в карточках и подробностях. Неизвестные будущие URL идут через CachedNetworkImage с локальным fallback известной конфигурации. Схема GTSh доступна и у гонки без пары DG-Edge. Модель DG-Edge предпочитает реальные URL из новой разметки и каталога вместо ненадёжного шаблона; SUGO получает корректные `logo1340-new.webp` и `back1340-new.webp`. Логотип добавлен в заголовок подробностей. Изображения профилей сохраняют прежний сетевой путь.

## Обновление

```sh
# Без сети: проверить существующий пакет и покрытие каталога
python3 tools/update_track_images.py --verify-only
# Добавить новые конфигурации и их графику из живого каталога
python3 tools/update_track_images.py --refresh-catalogue
# Дополнительно проверить validators существующих URL и заменить изменённые файлы
python3 tools/update_track_images.py --refresh-catalogue --check-remote
.fvm/flutter_sdk/bin/dart format lib/models/daily_races/track_image_assets.dart
```

Обычный запуск пропускает файлы с правильным SHA-256. Повторное обновление, в том числе с живым повторным открытием каталога, передало **0 байт изображений**. CDN иногда присылает WebP как application/octet-stream: инструмент проверяет реальную сигнатуру файла, HTML не принимает. Неизменные изображения разных конфигураций занимают один файл; старый неиспользуемый хеш-файл удаляется после полной успешной загрузки. Обновление не касается пакета автомобилей. Полный пакет не скачивается фоном на устройствах: это обновление assets перед выпуском приложения.

## Проверка

Регрессии проверяют все три роли/конфигурации и запрет profile URLs, настоящие race card/details при 390/1280, roundtrip реальных URL, bundled fallback, ETag/no-op, замену, восстановление повреждения, дедупликацию и отказ от HTML. Соседние dealer/card/catalogue tests сохранены.

Native macOS 1280px и iPhone 17e 390px: cold test entrypoint разрешает metadata HTTP и запрещает только пути изображений трасс. Гонки загрузились, локальные фото/схема/логотип отображаются. `blockedTrackImageRequests=[]` на обоих устройствах. Ошибок UI/изображений и overflow не обнаружено; одна неудачная команда Marionette scrollTo отражена в диагностике инструмента, к приложению/загрузке данных не относится. Тестовый entrypoint находится только в игнорируемом `.dart_tool`; после проверки обе платформы возвращаются на обычный `lib/main.dart` без HttpOverrides.

Evidence: `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/track-artwork/` — mac/phone cards/details и offline-status JSON. Автоматизация: `test/local_track_artwork_test.dart`, `test/local_track_updater_test.dart`. Анализ изменённых виджетов и тестов: No issues found. Legacy-модель гонок сохраняет прежние informational lint items.
