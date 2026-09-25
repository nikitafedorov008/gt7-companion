# GT7 Companion — Design System

## Overview
Design tokens extracted from gran-turismo.com and adapted for the GT7 Companion Flutter app.
Source pages: GT7 top page, sign-in page, CoolPicks discovery page.

The app uses a **dark theme** consistent with the official GT7 website aesthetic.

## Colors

### App Palette (adapted from GT7 website)
| Token | Hex | Usage |
|---|---|---|
| `background` | `#0B0D0F` | Scaffold background, deepest dark |
| `surface` | `#141619` | Cards, panels, input fields |
| `surfaceVariant` | `#1A1D21` | Elevated cards, secondary surfaces |
| `primary` | `#00D1E8` | Cyan/aqua — active states, gauges, highlights |
| `primaryContainer` | `#07282B` | Subtle cyan tint backgrounds |
| `accent` | `#6BE3FF` | Light cyan — secondary highlights |
| `secondary` | `#FFC857` | Warm yellow — badges, warnings, race indicators |
| `muted` | `#9AA3AC` | Disabled text, secondary labels |
| `onSurface` | `#E6EEF2` | Primary text on dark surfaces |
| `error` | `#FF5C5C` | Error states |

### Website Reference Tokens (gran-turismo.com)
| Token | Website Hex | App Adaptation |
|---|---|---|
| `surface` (site) | `#000000` | → `#0B0D0F` (slightly lifted pure black) |
| `onSurface` (site) | `#FFFFFF` | → `#E6EEF2` (softened white, easier on eyes) |
| `primary` (site) | `#A2A4AC` | Used for muted/disabled states |
| `primary` (top page) | `#0000EE` | Not used — too bright for dark theme |

## Typography

### Font Families
| Family | Usage | Flutter |
|---|---|---|
| **Roboto Condensed** | Headings, race data, condensed labels | `GoogleFonts.robotoCondensed` |
| **Roboto** | Body text, general UI | `GoogleFonts.roboto` |
| **Helvetica Neue** | System fallback | System default |
| **Barlow Condensed** | Data labels, compact displays | `GoogleFonts.barlowCondensed` |

### Type Scale (adapted for mobile)
| Style | Size | Weight | Line Height | Usage |
|---|---|---|---|---|
| `displayLarge` | 29dp | w300 (light) | 1.45 | Hero headings, race titles |
| `headlineSmall` | 21dp | w700 (bold) | 1.15 | Section headers |
| `titleLarge` | 20dp | w400 (regular) | 1.2 | Card titles |
| `titleMedium` | 18dp | w400 (regular) | 1.2 | Subsection titles |
| `bodyLarge` | 16dp | w400 (regular) | 1.5 | Body text |
| `bodyMedium` | 14dp | w400 (regular) | 1.3 | Secondary body text |
| `bodySmall` | 12dp | w500 (medium) | 1.2 | Labels, captions |
| `labelSmall` | 10dp | w500 (medium) | 1.2 | Tiny labels, badges |

## Spacing

Base unit: **8px**

| Token | Value | Usage |
|---|---|---|
| `xs` | 2dp | Tight internal padding |
| `sm` | 4dp | Compact spacing |
| `md` | 8dp | Standard spacing |
| `lg` | 12dp | Comfortable spacing |
| `xl` | 16dp | Section padding |
| `xxl` | 24dp | Large gaps |
| `xxxl` | 32dp | Section separation |

## Shapes (Border Radius)

| Token | Value | Usage |
|---|---|---|
| `sm` | 6dp | Small chips, tags |
| `md` | 8dp | Cards, inputs, buttons |
| `lg` | 12dp | Large cards, modals |
| `xl` | 50dp | Pills, circular buttons |

## Elevation & Shadows

| Level | Shadow | Usage |
|---|---|---|
| `elevation1` | `0 2px 6px rgba(0,0,0,0.25)` | Cards |
| `elevation2` | `0 0px 6px rgba(0,0,0,0.45)` | Modals |
| `elevation3` | `0 3px 6px rgba(0,0,0,0.16)` | Subtle lift |

## Components

### Buttons
| Type | Background | Text | Radius | Padding |
|---|---|---|---|---|
| Primary | `#00D1E8` | `#0B0D0F` | 8dp | 12dp 24dp |
| Secondary | `#1A1D21` | `#E6EEF2` | 8dp | 12dp 24dp |
| Ghost | transparent | `#E6EEF2` | 8dp | 8dp 16dp |
| Pill (website ref) | `#343434` | `#FFFFFF` | 50dp | 6dp 16dp |

### Cards
- Background: `#141619`
- Border radius: 8dp
- Elevation: level 1
- Padding: 16dp

### Inputs
- Background: `#141619`
- Border radius: 10dp
- Border: 1px `rgba(230,238,242,0.08)`
- Focus border: `rgba(0,209,232,0.85)`

### Gauges (Telemetry-specific)
- Track: `rgba(20,22,25,0.04)` on surface
- Active ring: `#00D1E8` with dynamic color transition (green → yellow → red)
- Needle: `#FFC857` (secondary)
- Labels: `#9AA3AC` (muted)

## Responsive Breakpoints

| Breakpoint | Usage |
|---|---|
| 360dp | Small phones |
| 530dp | Large phones / small tablets |
| 660dp | Tablets |
| 785dp | Desktop / landscape |

## Design Principles

1. **Dark-first** — The app is always dark, matching GT7's in-game aesthetic
2. **High contrast** — White/light text on dark backgrounds for readability
3. **Cyan accent** — Primary interactive color inspired by GT7's telemetry UI
4. **Warm yellow** — Secondary accent for race data, badges, warnings
5. **Minimal chrome** — Clean surfaces, subtle borders, low visual noise
6. **Data density** — Compact typography for telemetry data, no wasted space

## Notes

- The GT7 website uses both light (top page) and dark (sign-in, discovery) themes. The app uses the **dark** variant exclusively.
- Website uses px units; the app uses Flutter's dp (logical pixels), which map 1:1 on standard displays.
- Some website tokens (e.g., `#0000EE` blue links) are web-specific and not appropriate for the app's dark theme.
- Font families should be bundled via `google_fonts` package or included as assets for offline support.
