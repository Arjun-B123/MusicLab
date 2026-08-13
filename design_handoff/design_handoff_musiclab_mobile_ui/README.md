# Handoff: MusicLab Mobile UI — Warm Journal (Home, Library, Journey, Profile)

## Overview
Visual design for MusicLab's 4 bottom-tab screens, in a "Warm Journal" direction — handwritten headline accents, terracotta/sage/gold palette, paper-adjacent motifs (dashed underlines, colored highlight borders). Both a light and a dark theme are included for every screen.

## About the Design Files
The `.dc.html` files in this folder are **design references built in HTML** — prototypes showing intended look, layout, and basic interaction, not production code. The task is to **recreate these designs in the app's existing Flutter/Material 3 codebase** (`lib/core/theme/app_theme.dart` etc.) using Flutter widgets, not by embedding HTML/WebViews. Each file opens directly in a browser to view/interact with.

## Fidelity
**High-fidelity.** Colors, type, spacing, and copy below are final; recreate pixel-close using Flutter's layout system. Implement both themes as a real light/dark mode toggle (following system setting, with manual override in Profile), not as two disconnected designs.

## Screens (each has a Light and Dark file)

### Home Dashboard
**Purpose**: today's practice at a glance — resume current piece, see other pieces in progress, light weekly practice signal, recent diary snippets.

**Layout**: single scroll column inside a phone frame (412×892 reference viewport). Top to bottom:
1. Header: small uppercase date label, large handwritten-font greeting headline.
2. Hero "Continue practicing" card — rounded 20px, decorative thin colored bars in the top-right corner (evokes a piano roll / falling notes), piece title + composer + last-practiced, a thin 5-segment progress bar (filled segments = practiced sections), pill CTA button ("Keep going").
3. "Your pieces" — horizontal-scrolling row of cards (168px wide), each with a circular SVG progress ring (16px radius, 4px stroke), percentage, title, instrument + start date.
4. "This week" card — 7 dots (one per day, filled if practiced) + a bold one-line caption ("4 days this week · 52 minutes").
5. "Recent moments" — 2 stacked diary entries: quote text + piece name + date, separated by a dashed hairline divider.
6. Custom bottom tab bar (see Shared Components).

A `heroStyle` toggle (bold/soft) and `showWeekStrip` toggle exist in the prototype as tweaks — not required in the shipped app, just alternate treatments to reference.

### Library
**Purpose**: list all pieces, add a new one.

**Layout**: header "Your pieces" + piece count + "+ Add" pill button (top right). Vertical list of piece rows: circular progress ring (46px), title, instrument + goal, small status dot. Tapping "+ Add" opens a bottom sheet modal (slide up, rounded top corners 26px, dim scrim behind) with fields: Title (text), Instrument (single pill, Piano only for now), Goal (text), and a submit button.

### Journey
**Purpose**: chronological timeline of the user's musical journey — pieces started, milestones (% mastered), diary entries. Most recent at top.

**Layout**: vertical timeline, left-aligned rail (3px line) with 22px circular node markers per entry (filled accent for recordings/diary, gold for milestones, outlined/muted for "started" events). Each entry: small uppercase date label, then a rounded card with title + optional supporting body text.

### Profile
**Purpose**: account + subscription management.

**Layout**: header, avatar circle + email + instrument/join date. Subscription card (Pro: filled accent-colored card with renewal date + "Manage subscription"; Free: neutral card with upsell copy + "Upgrade to Pro" pill button — opens RevenueCat's hosted paywall). Below, a grouped list: Restore purchases, Manage subscription, Sign out — each a row with a small icon tile, label, and chevron.

## Shared Components

**Bottom tab bar** (all screens): 4 equal-width items (Home, Library, Journey, Profile). Active item gets a dashed underline beneath its label and a solid icon/label color; inactive items are muted.

**Device frame**: designs are shown inside an Android Material 3 phone frame for context only — not part of the UI to implement.

## Interactions & Behavior
- Tab bar: tapping a tab highlights it (in the prototype, each screen is a separate file, so tabs don't cross-navigate — implement real navigation to the corresponding tab in the app).
- Library "+ Add" opens/closes a modal bottom sheet; tapping the scrim or submitting closes it.
- Profile: `isPro` toggles between the Free/Pro subscription card states.

## Design Tokens

### Light theme
- Background: `#faf3ea` · Card surface: `#fff` · Card border/highlight: `#ecdfc9` (2px)
- Ink (primary text): `#3a2b22` · Ink soft: `#8a7a6d` / `#a3947f`
- Accent (terracotta): `#d97a4a` · Accent dark (hover/press): `#c15f30`
- Secondary accent (sage): `#8a9a7e` · Tertiary accent (gold, sparing use): `#f2c94c`
- Tab inactive: `#b0a494` · Dividers: `rgba(58,43,34,.1)` (or dashed for diary-style dividers)
- Fonts: **Kalam** (headlines/piece titles only — greeting, section headers, card titles) + **Inter** (all other UI text, 400–700 weight)

### Dark theme
- Background: `#201f1f` (neutral warm charcoal, not pure black)
- Card fill (all boxes — hero, piece cards, week strip, tab bar): `#DF781D` (saturated burnt orange)
- Card border: `#55483a`
- Text/icons on orange card fill: dark espresso `#2b1c10` (solid) or `rgba(43,28,16, 0.5–0.75)` for de-emphasized text; progress rings/bars use white (`#fff`) fill with `rgba(255,255,255,.3)` track for contrast
- Text on the plain dark background (headers, non-card text): cream `#f3ece1`, soft `#a3b39a` / `#c9bba8` / `#a5977f`
- Buttons on orange cards: white background, `#2b1c10` text
- Free-plan/neutral cards (Profile): `#3a3129` fill, `#55483a` border
- Fonts: same as light (Kalam headlines + Inter body)

### Shared
- Card radius: 16–20px
- Pill buttons: `border-radius: 100px`
- Progress rings: SVG circle, `stroke-width: 4–5`, `stroke-linecap: round`

## Assets
No custom icons or images — all icons are drawn as simple geometric shapes (circles, rounded squares, borders) in code. No external image assets used; replace with the app's own iconography if preferred.

## Files
- `Home Dashboard - Warm Journal (Light).dc.html` / `(Dark).dc.html`
- `Library - Warm Journal (Light).dc.html` / `(Dark).dc.html`
- `Journey - Warm Journal (Light).dc.html` / `(Dark).dc.html`
- `Profile - Warm Journal (Light).dc.html` / `(Dark).dc.html`
