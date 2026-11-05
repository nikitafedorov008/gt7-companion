# Beyond the Apex: GT7 reference review

Verified in Codex IAB on 2026-11-04 against primary sources:

- GT Menu manual: https://www.gran-turismo.com/ru/gt7/manual/option/01
- Official game-menu screenshot embedded in that manual: https://www.gran-turismo.com/images/c/i1JW0W38E4UVr.jpg
- Magazine: https://www.gran-turismo.com/ru/gt7/apex/

The GT logo opens a dark translucent menu. Beyond the Apex is a magazine item below Online Manual and above Return to map in the official screenshot. The manual describes opening the online magazine; it does not establish a separate native in-game article reader.

The official magazine uses a light editorial layout: white reading canvas, black text and bA wordmark, black top strip with white GT logo, thin neutral borders, restrained technical illustrations, generous whitespace. Desktop has a left contents rail and a wider article; chapter headings expand to article lists. The cover combines pale mechanical diagrams and the large black wordmark. Chapter headings are bold sans-serif; article diagrams retain their original pale/coloured annotations.

Computed colours observed on the rendered page:

| Role | Colour |
| --- | --- |
| Reading canvas, visually white | #FFFFFF |
| Article text, headings, top strip | #000000 |
| Chapter tiles | #F9FAFC |
| Secondary contents surfaces | #EDF2F4 |
| Chapter borders | #C3C3C3 |

These are web-reference values, not measurements of the game's compositor or a claim of a distinct console-native Apex theme. The game-menu screenshot uses a dark graphite overlay independently of the light magazine.

Implemented scope: GT Menu opens the Apex child route inside HomeShell under the existing navigation shell; close preserves the home stack and restores the previous tab. The reader now has a local light magazine theme below the existing dark AdaptiveNavBar, a page-level title and close button matching the dealers, official cover, square illustrations, pale outlined chapter tiles, Helvetica Neue with platform fallback, and the original article structure. Desktop uses a contents rail; phones and enlarged text use a drawer. The rest of the app retains its dark theme. Native navigation and safe areas adapt the online magazine to the app.

Validation: 131 selected tests pass (including theme isolation, official cover, article navigation, retry, localization and safe areas); changed-file analyzer clean. Quiet Mac and iPhone390 checks confirmed the cover, chapter expansion, article selection, return to cover and error-free hot reload. Current screenshots: `apex-style/mac-cover.png`, `apex-style/mac-article.png`, `apex-style/phone-cover.png`, `apex-style/phone-contents.png` under the same visualization root.

Evidence images are stored locally under `/Users/nikitafedorov008/.codex/visualizations/2026/10/24/01a16fa3-b3c5-7940-8ef0-df0224dab30a/apex-research/`: official-apex.png, official-gt-menu.png and app-gt-menu.png.
