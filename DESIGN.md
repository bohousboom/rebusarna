---
name: Rébusárna
description: Calm, card-led Material 3 UI where the puzzle image is the hero and color is reserved for difficulty.
colors:
  seed-indigo: "#3F51B5"
  difficulty-easy-teal: "#1ABC9C"
  difficulty-medium-yellow: "#F1C40F"
  difficulty-hard-red: "#E74C3C"
  card-white: "#FFFFFF"
  card-border: "#1F000000"
  ink-on-card: "#DD000000"
  favorite-red: "#FF5252"
  success-green: "#4CAF50"
typography:
  badge:
    fontFamily: "Platform default (Roboto on Android/web)"
    fontSize: "18px"
    fontWeight: 800
  title:
    fontFamily: "Platform default (Roboto on Android/web)"
    fontSize: "24px"
    fontWeight: 800
  body:
    fontFamily: "Platform default (Roboto on Android/web)"
    fontSize: "16px"
    fontWeight: 400
  caption:
    fontFamily: "Platform default (Roboto on Android/web)"
    fontSize: "13px"
    fontWeight: 400
rounded:
  badge: "12px"
  thumb: "14px"
  panel: "16px"
  card: "24px"
  card-image: "18px"
spacing:
  xs: "6px"
  sm: "10px"
  md: "12px"
  lg: "16px"
  xl: "24px"
components:
  puzzle-card:
    backgroundColor: "{colors.card-white}"
    rounded: "{rounded.card}"
    padding: "6px"
  difficulty-badge:
    backgroundColor: "{colors.difficulty-easy-teal}"
    textColor: "{colors.ink-on-card}"
    typography: "{typography.badge}"
    rounded: "{rounded.badge}"
    padding: "8px 12px"
  adult-chip:
    backgroundColor: "{colors.ink-on-card}"
    textColor: "{colors.card-white}"
    rounded: "{rounded.badge}"
    padding: "6px 8px"
  button-filled:
    height: "52px"
    width: "48px"
---

# Design System: Rébusárna

## Overview

**Creative North Star: "The Puzzle Card Deck"**

Rébusárna is a pack of picture cards you flip through. Each rébus sits in a white, rounded card that takes the stage; everything around it is stock Material 3, tonal and quiet, generated from a single indigo seed (#3F51B5) in both light and dark. The mood is calm and focused: surfaces stay out of the way so the player can think, and saturated color appears only where it carries information.

Color is a signal, not decoration. The one loud element is the corner badge on a card, whose fill encodes difficulty (teal, yellow, red) and whose symbols (`?`, `±`, word-type icon) are the game's own vocabulary. Depth is a single soft shadow under the card; the rest of the app is flat tonal Material.

**Key Characteristics:**
- Material 3 with `ColorScheme.fromSeed` (indigo #3F51B5), light and dark; no custom fonts.
- The puzzle card is the signature: white mat, 24px corners, image inset 6px.
- Difficulty is the only saturated color system; it is always paired with symbols and a text tooltip.
- Large touch targets: filled and outlined buttons are at least 52px tall, icon buttons 48px.

## Colors

A quiet indigo-seeded Material scheme with three signal colors for difficulty.

### Primary
- **Seed Indigo** (#3F51B5): the seed for the whole Material 3 scheme (primary, containers, surfaces, nav indicator). Individual role values are derived by Flutter, not hand-picked.

### Secondary
- **Easy Teal** (#1ABC9C): difficulty 1 (lehká) badge fill.
- **Medium Yellow** (#F1C40F): difficulty 2 (střední) badge fill.
- **Hard Red** (#E74C3C): difficulty 3 (těžká) badge fill.

### Neutral
- **Card White** (#FFFFFF): the puzzle card surface, in light and dark alike so the image keeps its own background.
- **Card Hairline** (black at 12%): 1px card border.
- **Ink on Card** (black at 87%): text and icons on pale badges, the 18+ chip fill.
- **Favorite Red** (#FF5252): the heart. **Success Green** (#4CAF50): the 4px card highlight after a correct guess.

### Named Rules
**The Signal-Only Rule.** Saturated color means difficulty, favorite, or correct. Never use teal, yellow or red as decoration or for non-difficulty states.
**The Label-Behind-Color Rule.** A color never stands alone: the badge always carries symbols and a tooltip naming the difficulty in Czech.

## Typography

**Display / Body / Label Font:** the platform default of Material 3 (Roboto on Android and web, system font on iOS).

**Character:** unadorned and legible. Weight, not family, builds hierarchy: heavy 800 for badge symbols and titles, regular for body.

### Hierarchy
- **Title** (800, 24px): dialog and sheet headings.
- **Badge** (800, 18px; 14px for the 18+ chip): the `?` and `±` symbols.
- **Body** (400, 16px, Material default line height): prompts and explanations.
- **Caption** (400, 11–13px): thumbnails, inline notes and fine print.

### Named Rules
**The Czech-Diacritics Rule.** Every text style must render ě š č ř ž ý á í é ú ů ď ť ň without clipping; do not choose a typeface or size that crowds the caron.

## Layout

A single column, feed-first. The play screen centers one card at a time; lists (Moje, new puzzles) use thumbnails in rows. Screen padding is 12–24px; common steps are 6, 10, 12, 16, 24. A bottom `NavigationBar` switches the main sections. It must stay usable from 360px width, and the web build uses the same single-column layout. Touch targets are 48px minimum.

## Elevation & Depth

Hybrid: tonal Material surfaces plus one structural shadow. The puzzle card lifts off the background with a soft ambient shadow; nothing else is raised by default.

### Shadow Vocabulary
- **Card lift** (`box-shadow: 0 4px 10px rgba(0,0,0,0.26)`): the puzzle card only.

### Named Rules
**The One Lift Rule.** Only the puzzle card casts a shadow; every other surface is tonal and flat.

## Shapes

Generously rounded and nested: 24px card, 18px image inside a 6px mat, 16px panels, 14px thumbnails, 12px badges and chips. The image radius follows the card curve (outer minus mat). Text inputs use the default Material outline border.

## Components

### Puzzle Card
Character: a framed picture card. White (#FFFFFF), 24px corners, 1px hairline border, 6px inset image (18px radius, `BoxFit.contain`), card lift shadow, 300 ms animated container. A correct guess shows a 4px green border; tapping the image opens a full-screen black viewer with pinch zoom (up to 5x), faded in over 200 ms.

### Difficulty Badge
Top-left, 12px radius, 8×12px padding, fill by difficulty, text and icons black87 or white by contrast. Holds `?` (always), `±` (when the solution has no acute accents), and word-type icons at 22px, each with a tap tooltip.

### Chips and flags
18+ chip: black87 pill, white 800 text at 14px, 12px radius.

### Buttons
Material 3 filled and outlined, minimum 52px tall. Icon buttons on the card are 48px with a translucent white (70%) circle behind them; the heart is Favorite Red.

### Inputs
Material outline text field with the default focus treatment.

### Navigation
Material 3 `NavigationBar` at the bottom, indicator tinted from the seed.

## Do's and Don'ts

### Do:
- **Do** let the puzzle image dominate each screen; keep surrounding chrome tonal.
- **Do** derive all non-difficulty color from the indigo seed via the Material scheme.
- **Do** pair difficulty color with symbols and a Czech text label.
- **Do** keep touch targets at 48px or larger, and keep the layout working at 360px.

### Don't:
- **Don't** use teal, yellow or red for anything but difficulty (or red for favorite).
- **Don't** add a second shadow style or lift other surfaces.
- **Don't** introduce a custom typeface or decorative display type.
- **Don't** make search, browsing or answer-revealing UI prominent; the game depends on not trivializing it.
