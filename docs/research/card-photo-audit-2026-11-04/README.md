# Аудит изображений карточек: Used, Legendary и Brand Central

Снимок: 2026-11-04T15:56:52.162195+00:00. Размеры получены полным GET каждого файла, не по выборке и не по Content-Length.

**Фотографии: 770 уникальных файлов, 30.071 MB / 28.678 MiB.**
Проверено 770 из 770 URL; недоступных фотографий: 0.

| Набор | Уникальных URL | Получено | Размер файлов до дедупликации содержимого |
|---|---:|---:|---:|
| Официальные миниатюры GT — общий набор для трёх разделов | 580 | 580 | 20.255 MB / 19.317 MiB |
| GTDB Used — отдельные дилерские фото | 120 | 120 | 7.689 MB / 7.333 MiB |
| GTDB Legendary — frontImage / Hagerty Front | 70 | 70 | 2.127 MB / 2.028 MiB |

## Дедупликация и покрытие

- 859 ссылок с учётом источников свёрнуты в 770 URL; повторных ссылок: 89.
- После SHA-256 остаётся 770 разных файлов. Экономия от одинакового содержимого по разным URL: 0.000 MB / 0.000 MiB.
- Для набора «все официальные миниатюры + фотографии сегодняшнего GTDB ассортимента» достаточно 628 файлов, 22.981 MB / 21.916 MiB.
- Официальная база покрывает 580 машин. Публичный каталог GTDB содержит 560 моделей, из них 130 помечены Used Cars и 68 — Legend Cars. Обойдены все 198 страниц; ошибок получения страниц: 0.
- У 120 из 130 Used-моделей найден отдельный Used Car Dealer Photo. У всех 68 Legendary найден Hagerty Front; текущий API добавил ещё два уникальных варианта frontImage.
- Снимок не обещает все исторические цвета/версии фотографий GTDB или будущие URL после обновлений. Официальные fallback всех 580 машин включены.

## Что именно включено

- Brand Central: только `ShowroomCar.thumbnail`, PNG из `car_thumbnails/car<ID>.png`.
- Used/Legendary: тот же официальный PNG как основной источник/fallback; GTDB Used Car Dealer Photo и GTDB frontImage / Hagerty Front, соответствующие выбору в CarRepository и карточках дилеров.
- GT7Info даёт IDs/ассортимент, а не дополнительный фотохостинг. Его стандартные картинки уже входят в официальный набор.
- Для GTDB установлен `Accept: image/avif`, как у используемого приложением AvifImage.network. Реальный MIME и SHA-256 каждого ответа записаны в CSV/JSON.
- Исключены галереи GT и GTDB, фоновые изображения экранов, рекламные изображения, графики цен и фотографии других игр.

## Прочие изображения интерфейса — отдельно от фотографий машин

| Набор | URL | Получено | Размер полученных файлов |
|---|---:|---:|---:|
| Флаги Used (flagcdn.com) | 5 | 5 | 0.001 MB / 0.001 MiB |
| Логотипы в карточках Legendary (vl.imgix.net) | 6 | 6 | 0.047 MB / 0.045 MiB |
| Логотипы селектора брендов Brand Central, вне автомобильных карточек | 77 | 77 | 2.276 MB / 2.171 MiB |

Фотографии вместе с успешно полученными флагами Used и логотипами Legendary: 30.119 MB / 28.724 MiB. Логотипы селектора брендов в эту сумму не входят.

## Обнаруженные проблемы

- Старый `https://api.playstationdb.com/graphql`, используемый GTDBService для Used, не проходит TLS-проверку имени хоста. Проверка сертификата не отключалась; вместо него для инвентаризации использованы публичные страницы GTDB.
- GTDB-конвертер записывает ID с префиксом `car`, а стандартный fallback дополнительно приписывает `car`. Для самостоятельных GTDB-карточек возможен `carcar<ID>.png`. Контрольный адрес `carcar344.png` ответил 404. В объединённых карточках с числовым GT7Info ID этой ошибки может не быть.
- Неизвестная страна GTDB задаётся как `xx`; `https://flagcdn.com/h24/xx.png` ответил 404. Эти несуществующие файлы не включены в сумму.

### Used без отдельного дилерского фото

- [volvo-240-se-estate-93](https://gtdb.io/gt7/car/volvo-240-se-estate-93/)
- [ferrari-430-scuderia-07](https://gtdb.io/gt7/car/ferrari-430-scuderia-07/)
- [renault-avantime-3-0-v6-24-v-02](https://gtdb.io/gt7/car/renault-avantime-3-0-v6-24-v-02/)
- [honda-civic-si-r-ii-eg-93](https://gtdb.io/gt7/car/honda-civic-si-r-ii-eg-93/)
- [chevrolet-corvette-z06-c5-01](https://gtdb.io/gt7/car/chevrolet-corvette-z06-c5-01/)
- [impreza-sedan-wrx-s-ti-04](https://gtdb.io/gt7/car/impreza-sedan-wrx-s-ti-04/)
- [mitsubishi-lancer-evolution-ix-mr-gsr-06](https://gtdb.io/gt7/car/mitsubishi-lancer-evolution-ix-mr-gsr-06/)
- [bmw-m3-97](https://gtdb.io/gt7/car/bmw-m3-97/)
- [audi-tts-coupe-09](https://gtdb.io/gt7/car/audi-tts-coupe-09/)
- [bmw-z4-3-0i-03](https://gtdb.io/gt7/car/bmw-z4-3-0i-03/)

### Недоступные изображения

Нет.

## Файлы и воспроизведение

- `photos.csv` / `photos-only.json` — только 770 фотографий автомобилей, без логотипов и флагов.
- `manifest.json` — уникальные URL, группы и источники, включая отдельно помеченную служебную графику.
- `measurements.json` / `images.csv` — фактический размер, MIME, SHA-256, статус и ошибки каждого файла.
- `unique-files.json` — файлы, объединённые по содержимому, со всеми URL-алиасами.
- `discovery.json` — результаты обхода 198 дилерских моделей; `sources/` — публичные исходные снимки.
- `diagnostics.json` — проверки некорректных fallback-адресов.

```sh
cp -R docs/research/card-photo-audit-2026-11-04/sources /tmp/gt7-card-photo-input
python3 tools/audit_card_images.py \
  --input-dir /tmp/gt7-card-photo-input \
  --output-dir /tmp/gt7-card-photo-audit
```

Скрипт сохраняет только метаданные; тела изображений после подсчёта/хэширования отбрасываются. Кэш страниц/успешных измерений позволяет продолжить прерванную проверку; `--refresh` повторно измеряет файлы. Само приложение и способ хранения изображений не изменены.

Источники: [GT7](https://www.gran-turismo.com/us/gt7/carlist/), [GTDB Used](https://gtdb.io/gt7/used-cars/), [GTDB каталог](https://gtdb.io/gt7/all-cars/), [LegendCarsDealer API](https://gtdb.io/api/graphql_middleware/query/LegendCarsDealer), [GT7Info](https://ddm999.github.io/gt7info/data.json).
