---
name: artifact-rules
description: Readability rules for every artifact and HTML page built for viewing. No rendered text below 18px, and every text colour meets WCAG 2.2 AAA contrast (7:1) in both light and dark themes. Auto-invoke whenever building, editing, restyling or republishing an artifact, an HTML page, a dashboard, a report page, a doc page, a chart or an SVG diagram meant to be read, before writing its CSS.
---

# artifact-rules

Two rules for anything rendered for a person to read. They hold in both themes, at every width, and override any design choice that conflicts.

## 1. No text below 18px

Every piece of rendered text computes to 18px or larger. That includes:

- body copy, table cells, captions, footnotes and legends;
- labels, eyebrows, badges, chips, tags and tooltips;
- code, inline and in blocks;
- buttons, inputs, placeholders and select options;
- chart axis labels, tick labels, data labels and SVG `<text>`.

How to hold it:

- Set `body { font-size: 18px }` or larger. A `rem` value resolves against the root, which is usually 16px, so `1rem` is 16px and fails. Use `1.125rem` or more, or plain pixels.
- An `em` value compounds through its parents. Check the computed size of nested `em` text.
- SVG text scales with its `viewBox`. A `font-size="18"` inside a viewBox drawn at half size renders at 9px. Size the viewBox so text renders at 18px or more on screen.
- Build hierarchy with weight, colour, case, letter-spacing and space. Never make secondary text smaller than 18px.
- Wide tables keep 18px text and scroll inside an `overflow-x: auto` container.

## 2. WCAG 2.2 AAA contrast

Success criterion 1.4.6, enhanced contrast.

| Text | Minimum ratio |
| --- | --- |
| Under 24px regular, or under 18.66px bold | 7:1 |
| 24px regular and up, or 18.66px bold and up | 4.5:1 |

With an 18px floor, most body and label text sits in the 7:1 row. Default every text colour to 7:1, and use 4.5:1 only for headings that are verifiably large.

The ratio applies to every text and background pair the page can show:

- muted and secondary text, links, visited links, and hover and focus states;
- text on chips, badges, callouts, table header fills and code backgrounds;
- placeholder text, and disabled text that still carries information;
- chart labels against the chart background;
- text over an image or gradient, measured at its worst point.

Check each pair in the light theme and again in the dark theme. Both themes must pass on their own.

Non-text parts that someone needs to see, such as input borders, focus rings, chart marks and icons that carry meaning, need at least 3:1 against what sits beside them. Never use colour alone to carry meaning. Pair it with text, an icon or a pattern.

## Check before publishing

Contrast. Run the checker on every foreground and background token pair, once per theme:

```bash
python3 ~/.claude/skills/artifact-rules/contrast.py 1d2421 f6f7f5 3d4742 ffffff
```

It prints the ratio for each pair and exits 1 if any pair is below 7:1. Fix the token and run it again. For a pair that is verifiably large text, 4.5:1 is the bar, so read that line's ratio yourself.

Text size. When a rendered preview is available, run this in the page and expect an empty list:

```js
[...document.querySelectorAll('body *')]
  .filter(el => [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()))
  .filter(el => parseFloat(getComputedStyle(el).fontSize) < 18)
  .map(el => `${el.tagName.toLowerCase()}.${el.className} ${getComputedStyle(el).fontSize}`)
```

Without a preview, read every `font-size` declaration in the CSS, and every `font-size` attribute in SVG, and confirm each resolves to 18px or more on screen.
