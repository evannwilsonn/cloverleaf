---
name: Cloverleaf
description: Bay Area freeway traffic counted from live Caltrans cameras, drawn as route strip maps.
colors:
  ground: "#e3e1dc"
  paper: "#f6f5f1"
  paper-2: "#eceae4"
  rule: "#cfccc4"
  rule-2: "#b4b0a6"
  ink: "#221b25"
  ink-2: "#4d4450"
  ink-3: "#6c6470"
  plum: "#5a2860"
  plum-2: "#7d4784"
  lime: "#bcd93a"
  lime-deep: "#55650a"
  ground-dark: "#1c1c1a"
  paper-dark: "#262624"
  paper-2-dark: "#2f2f2c"
  rule-dark: "#3c3b37"
  rule-2-dark: "#56544e"
  ink-dark: "#f1ecf2"
  ink-2-dark: "#c9bfcc"
  ink-3-dark: "#a096a4"
  plum-dark: "#d5a6dc"
  plum-2-dark: "#b986c1"
  lime-dark: "#c6e34c"
  lime-deep-dark: "#d4ec74"
typography:
  display:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "clamp(28px, 4vw, 40px)"
    fontWeight: 800
    lineHeight: 1
    letterSpacing: "-0.02em"
  headline:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "22px"
    fontWeight: 800
    lineHeight: 1.2
    letterSpacing: "-0.01em"
  title:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 700
    lineHeight: 1.3
  body:
    fontFamily: "Archivo, system-ui, sans-serif"
    fontSize: "15px"
    fontWeight: 400
    lineHeight: 1.55
  label:
    fontFamily: "Archivo Narrow, Archivo, system-ui, sans-serif"
    fontSize: "12px"
    fontWeight: 600
    lineHeight: 1.35
  numeral:
    fontFamily: "DM Mono, ui-monospace, Menlo, monospace"
    fontSize: "20px"
    fontWeight: 500
    lineHeight: 1.15
  data:
    fontFamily: "DM Mono, ui-monospace, Menlo, monospace"
    fontSize: "12.5px"
    fontWeight: 400
    lineHeight: 1.5
rounded:
  none: "0px"
spacing:
  gutter: "22px"
  sheet: "16px"
  section: "44px"
components:
  route-badge:
    backgroundColor: "{colors.plum}"
    textColor: "{colors.paper}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "5px 7px 4px"
  sheet:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.none}"
    padding: "16px"
  reading-panel:
    backgroundColor: "{colors.paper}"
    rounded: "{rounded.none}"
    width: "360px"
  ledger-bar:
    backgroundColor: "{colors.plum}"
    height: "6px"
  ledger-bar-counted:
    backgroundColor: "{colors.lime}"
    height: "6px"
  theme-button:
    textColor: "{colors.ink-2}"
    typography: "{typography.label}"
    rounded: "{rounded.none}"
    padding: "4px 10px"
---

# Design System: Cloverleaf

## Overview

**Creative North Star: "The Route Strip Map"**

Cloverleaf reads like a Caltrans corridor sheet laid on a concrete desk: every freeway is one long paper strip drawn to a shared mileage scale, each camera sits where it really is, and its mark says what that camera delivered. Plum carries the lines, marks and badges; chartreuse-lime is the only thing that means "vehicles flowing". Everything else is grey ground, warm paper and ink.

The system is dense and flat, square-cornered, and numeric. Counts and times are set in mono, labels in a narrow grotesque, prose in Archivo. Depth comes from paper on ground and hairline rules, never from shadow. State is carried by shape and pattern first, colour second, so the page holds up in greyscale and in dark mode.

**Key Characteristics:**
- One mileage scale across every strip; distance is honest and labelled approximate.
- Four camera-state shapes reused everywhere a capture appears (strip, panel, tape).
- Lime for flow only; plum for structure and state.
- Square corners, 1px rules, no shadows.
- Concrete and paper in light; neutral charcoal (not plum-tinted) in dark.

## Colors

Two-accent palette on neutral concrete: plum for structure, lime for flow.

### Primary
- **Deep Route Plum** (plum): route lines, mile ticks, end caps, camera marks, route badges, ledger bars for exclusions, masthead and footer 2px rules, links, focus outline. In dark mode it lifts to a pale orchid (plum-dark) so marks keep contrast on charcoal.
- **Faded Plum** (plum-2): secondary plum; reserved, lightly used.

### Secondary
- **Chartreuse Flow** (lime): vehicles-per-minute bars above camera marks and the "counted" ledger bar. Fill only, never text on light paper.
- **Olive Verdict** (lime-deep): the readable text form of lime, used for "met" target verdicts.

### Neutral
- **Concrete Ground** (ground): page background.
- **Strip Paper** (paper): strips, sheets, reading panel, and the knock-out disc behind each mark.
- **Under-Paper** (paper-2): still placeholder, the "before collection began" band on the tape, the inline panel on narrow screens.
- **Hairline** (rule) and **Heavy Hairline** (rule-2): row and sheet borders; rule-2 for table heads, label leaders, missed slots, not-attempted outlines.
- **Ink** (ink), **Ink 2** (ink-2), **Ink 3** (ink-3): primary text and numerals; lede, deks and strip labels; metadata, axes, captions.

Dark mode swaps every token to its `-dark` value under `prefers-color-scheme: dark` and `[data-theme="dark"]`, with `[data-theme="light"]` forcing light. The dark ground is neutral charcoal; the plum hue lives in marks, lines, badges and small link-weight text.

### Named Rules
**The Flow Is Lime Rule.** Lime means counted vehicles per minute and nothing else. It never marks state, selection or decoration.

**The Plum Title Rule.** The masthead title is plum in light mode and ink in dark mode (a separate `--title` token). Purple text on a dark ground reads as low-energy and fails as display type, so in dark mode plum stays on marks and lines and the title goes to ink.

**The No Blue, No Orange Rule.** No blue, orange or sign-green anywhere. Those belong to sister projects; Cloverleaf keeps its own palette.

## Typography

**Display Font:** Archivo (with system-ui)
**Label Font:** Archivo Narrow (with Archivo)
**Mono Font:** DM Mono (with ui-monospace, Menlo)

**Character:** A plain engineering grotesque in three widths of voice. Archivo speaks, Archivo Narrow labels the drawing, DM Mono reports the measurements.

### Hierarchy
- **Display** (800, clamp(28px, 4vw, 40px), 1, -0.02em): the masthead name only.
- **Headline** (800, 22px, 1.2): section heads, followed by a dek in ink-2 at 72ch max.
- **Title** (700, 15–18px): sheet heads (15px) and the camera name in the reading panel (18px).
- **Body** (400, 15px, 1.55): lede (66ch), deks, pipeline steps. Captions and hints drop to 12–12.5px in ink-3.
- **Label** (600, 11.5–13px, Archivo Narrow): key entries, strip camera labels, table heads, tape header, verdicts, panel state line (14px). Sentence case; no tracking, no uppercase.
- **Numeral** (DM Mono 500, 20–21px): route summary per-minute figures and panel readings. Mono 400–500 at 11–13.5px for axes, run line, table figures, footer.

### Named Rules
**The Mono Means Measured Rule.** Every count, rate, time and mile is DM Mono; prose and labels never are.

## Layout

A single 1360px column (padding 22px top, clamp(16px, 3vw, 36px) sides). The masthead is a three-part grid (name, lede, run line right-aligned in mono) above a 2px plum rule; under 860px it stacks.

The board is strips plus a 360px reading panel with a 22px gutter. The panel is sticky (top 14px) beside the strips. At 1080px and below the board goes single-column and the panel moves inline directly under the strip whose camera was tapped, on paper-2 with only top and bottom borders, and scrolls into view (instant under reduced motion).

Each strip is a three-column row (96px route, flexible line, 128px summary). Under 700px it becomes route and summary on one line, the line full width below. Strip geometry: plum line 3px with 2px end caps and direction letters (W/E or N/S), mile ticks every 5 or 10 mi, marks pushed at least 21px apart, labels in non-crossing lanes on rule-2 leaders.

Sections sit 44px apart; paired sheets use a two-column grid that stacks under 900px. Ledger columns marked hide-s drop under 600px.

## Elevation & Depth

Flat. No box-shadows anywhere. Depth is paper (paper) laid on concrete (ground) with 1px hairlines, and the only overlay is the dark translucent stamp on the camera still.

### Named Rules
**The Paper On Concrete Rule.** A surface is distinguished by being paper on ground with a 1px rule, never by lift.

## Shapes

Square corners throughout (0px): badges, sheets, panel, buttons, bars, chart columns. Rounded geometry belongs only to camera marks, which are circles because their shape is data:

- **Filled disc**: counted.
- **Half disc** (left half filled, ring outline): picture delivered, not countable.
- **Ring**: no picture.
- **Cross** (square caps): feed offline.
- **Dashed grey ring**: no capture yet.

Each mark sits on a paper knock-out disc so it reads over the line. In the runs chart the same states become stacked rectangles: solid plum, a 45-degree plum hatch on paper, plum outline, dashed plum outline, dotted rule-2 for not attempted.

## Components

### Route Strip
One per freeway, all at one miles-to-pixels scale. Lime flow bar (14px wide, up to 30px tall, scaled to the max rate) above each counted mark with its mono figure on top; label below on a leader. Marks are focusable buttons: hover gives a plum-wash halo, selection and focus give a 2px plum halo ring. Arrow keys step along all marks.

### Route Badge
Plum block, paper text, Archivo Narrow 700 15px (14px on phones), square. Mono camera count beneath.

### Reading Panel
Paper, 1px rule. 4:3 still with a mono stamp top-left, camera name, mono metadata, a state line (mark plus label and reason) between hairlines, three mono readings, and a 48-hour capture tape that repeats the mark shapes on a time line with a paper-2 band for time before collection began.

### Runs Chart
One day on a time-of-day axis (12am to 12am, 3h labels, 6h under 640px). Each run is a stacked bar at its actual start time, coloured by camera state, with vehicles per minute on top (or "dark"). Slot ticks under the axis: filled plum where a scheduled half-hour slot ran, open rule-2 where it was missed.

### Ledger
Full-width table, Archivo Narrow heads over a rule-2 line, rows on hairlines, mono right-aligned figures, ink-3 description under the label, 6px bar (lime for counted, plum for exclusions and dark). Verdicts in Narrow: "met" in olive, "missed" in bold plum.

### Sheet
Paper, 1px rule, 16px padding, 15px title and 12.5px ink-3 sub.

### Theme Button
Transparent, 1px rule-2 border, Archivo Narrow 600 12px in ink-2, square.

## Do's and Don'ts

### Do:
- **Do** draw every corridor at the shared mileage scale and label distance as approximate.
- **Do** carry camera state by mark shape (and hatch/outline in charts), with plum as the only state colour.
- **Do** keep lime for flow quantities; use lime-deep when it must be text.
- **Do** set every number in DM Mono.
- **Do** switch the title to ink in dark mode; keep plum on marks and lines.
- **Do** keep corners square and surfaces flat.

### Don't:
- **Don't** add KPI tiles or a map with pins; the strip is the map.
- **Don't** introduce blue, orange or sign-green.
- **Don't** use drop shadows or rounded cards.
- **Don't** set plum as display or heading text on the dark ground; in dark mode the pale orchid appears as text only in links, pipeline step names and verdicts.
- **Don't** encode camera state by hue alone.
