

# Quarto footnote styles

- [Installation](#installation)
- [Usage](#usage)
- [Options](#options)
  - [`style`](#style)
  - [`custom`](#custom)
  - [`cycle`](#cycle)
  - [`marker-prefix` and
    `marker-suffix`](#marker-prefix-and-marker-suffix)
  - [`text-prefix` and `text-suffix`](#text-prefix-and-text-suffix)
  - [`start-at`](#start-at)
- [Examples](#examples)
  - [Symbols with doubling](#symbols-with-doubling)
  - [Roman numerals with period
    separator](#roman-numerals-with-period-separator)
  - [Custom symbols with restart](#custom-symbols-with-restart)
  - [Padded numbers with separator starting at
    3](#padded-numbers-with-separator-starting-at-3)
- [Format support](#format-support)
- [Customizing CSS](#customizing-css)

<!-- README.md is generated from README.qmd. Please edit that file -->

This extension replaces Quarto’s default numeric footnote numbering with
several alternative numbering systems, inspired by Adobe InDesign’s
numbering styles.

| Style         | Sequence                    |
|---------------|-----------------------------|
| `numeric`     | 1, 2, 3, 4, … (default)     |
| `numeric-02`  | 01, 02, 03, …               |
| `numeric-03`  | 001, 002, 003, …            |
| `alpha-lower` | a, b, c, … z, aa, ab, …     |
| `alpha-upper` | A, B, C, … Z, AA, AB, …     |
| `roman-lower` | i, ii, iii, iv, v, …        |
| `roman-upper` | I, II, III, IV, V, …        |
| `symbols`     | \*, †, ‡, §, ¶, \*\*, ††, … |
| `asterisk`    | \*, \*\*, \*\*\*, …         |

You can also define your own custom numbering system.

The extension supports HTML, LaTeX/PDF, and Typst. It does not support
Word because Word makes it impossible(?!) to programmatically adjust
these kinds of footnote settings.

## Installation

To install this extension in your current directory (or into the Quarto
project that you’re currently working in), use the following terminal
command:

``` sh
quarto add andrewheiss/quarto-footnote-styles
```

This will install the extension in the `_extensions` subdirectory. If
you’re using version control, you will want to check in this directory.

## Usage

Enable the filter by including it in your YAML front matter. Define the
style you want to use with `extensions.footnote-styles.style`.

``` yaml
---
title: Your title
filters:
  - footnote-styles
extensions:
  footnote-styles:
    style: "symbols"
---
```

Then use footnotes as normal:

``` markdown
This is some text with a footnote.[^1]

[^1]: The footnote content.
```

Using the `symbols` style, the footnote symbol will render as a `*`
instead of a `¹`.

## Options

``` yaml
---
title: Your title
filters:
  - footnote-styles
extensions:
  footnote-styles:
    style: "symbols"
---
```

All options go under `extensions.footnote-styles` in your YAML metadata.

### `style`

You can use one of nine predefined numbering systems:

| Style         | Sequence                    |
|---------------|-----------------------------|
| `numeric`     | 1, 2, 3, 4, … (default)     |
| `numeric-02`  | 01, 02, 03, …               |
| `numeric-03`  | 001, 002, 003, …            |
| `alpha-lower` | a, b, c, … z, aa, ab, …     |
| `alpha-upper` | A, B, C, … Z, AA, AB, …     |
| `roman-lower` | i, ii, iii, iv, v, …        |
| `roman-upper` | I, II, III, IV, V, …        |
| `symbols`     | \*, †, ‡, §, ¶, \*\*, ††, … |
| `asterisk`    | \*, \*\*, \*\*\*, …         |

``` yaml
extensions:
  footnote-styles:
    style: "numeric-03"
```

### `custom`

You can provide your own list of symbols too. For instance, if you want
to use this alternative set of symbols, define it with `custom`:

``` yaml
extensions:
  footnote-styles:
    custom: ["†", "‡", "§", "‖"]
```

The first footnote will now use `†` as the symbol, followed by `‡`, and
so on.

The `custom` setting overrides whatever you define in `style`. Custom
symbols follow the same cycling behavior as the `symbols` style
(controlled by the `cycle` option).

### `cycle`

The `cycle` setting controls what happens when the symbol set is
exhausted. Only applies to `symbols`, `asterisk`, and `custom` styles.
The default is `"repeat"`.

- **`repeat`**: Double up each symbol and cycle again: \*, †, ‡, §, ¶,
  \*\*, ††, ‡‡, §§, ¶¶, \*\*\*, …
- **`restart`**: Start over from the beginning: \*, †, ‡, §, ¶, \*, †, …

### `marker-prefix` and `marker-suffix`

Text placed before and after the marker. Defaults: none. In HTML,
applies only to the inline superscript; in LaTeX and Typst it applies to
every occurrence of the marker (both inline and in the footnote list).

``` yaml
extensions:
  footnote-styles:
    style: "roman-lower"
    marker-prefix: "["
    marker-suffix: "]"
```

This wraps the inline reference in brackets: `[i]`, `[ii]`, `[iii]`, …

Supported in HTML, LaTeX/PDF, and Typst.

### `text-prefix` and `text-suffix`

Text placed before and after the marker in the footnote list at the
bottom of the page. Defaults: none.

``` yaml
extensions:
  footnote-styles:
    style: "roman-lower"
    text-suffix: "."
```

This produces footnotes like:

       i.  First footnote text.
      ii.  Second footnote text.
     iii.  Third footnote text.
    viii.  Eighth footnote text.

The markers are right-aligned, so suffixes like `.` and `)` align neatly
regardless of marker width. Spacing between the suffix and the footnote
text is handled automatically by CSS.

You can combine a prefix and suffix for styles like `(i).`, `(ii).`, …:

``` yaml
extensions:
  footnote-styles:
    style: "roman-lower"
    text-prefix: "("
    text-suffix: ")."
```

> [!NOTE]
>
> `text-prefix` and `text-suffix` are HTML-only. LaTeX and Typst do not
> support independent formatting of the footnote list marker. Use
> `marker-prefix`/`marker-suffix` if you want prefix/suffix to appear
> consistently in both the inline mark and the footnote list.

### `start-at`

The `start-at` setting controls which marker the first footnote uses.
Default: `1`.

``` yaml
extensions:
  footnote-styles:
    style: "roman-lower"
    start-at: 4
```

With `start-at: 4`, the first footnote in the document uses the fourth
marker in the sequence (`iv` for `roman-lower`, `D` for `alpha-upper`,
`§` for `symbols`, etc.). This is useful when a document is part of a
series and footnote numbering needs to continue from where a previous
piece left off.

## Examples

See the different `.qmd` files in the `examples/` folder in this
repository for examples of each built-in style and for an example of
custom styles. Some shorter illustrations are included here too.

### Symbols with doubling

``` yaml
extensions:
  footnote-styles:
    style: "symbols"
```

In Markdown:

``` default
This^[1] is^[2] a^[3] sentence^[4] with^[5] lots^[6] of^[7] notes^[8] in it.
```

In the text:

> This<sup>\*</sup> is<sup>†</sup> a<sup>‡</sup> sentence<sup>§</sup>
> with<sup>¶</sup> lots<sup>\*\*</sup> of<sup>††</sup>
> notes<sup>‡‡</sup> in it.

### Roman numerals with period separator

``` yaml
extensions:
  footnote-styles:
    style: "roman-upper"
    separator: "."
```

In Markdown:

``` default
This^[1] is^[2] a^[3] sentence^[4] with^[5] lots^[6] of^[7] notes^[8] in it.
```

In the text:

> This<sup>I</sup> is<sup>II</sup> a<sup>III</sup> sentence<sup>IV</sup>
> with<sup>V</sup> lots<sup>VI</sup> of<sup>VII</sup>
> notes<sup>VIII</sup> in it.

In the notes:

``` default
   I. 1
  II. 2
 III. 3
  IV. 4
   V. 5
  VI. 6
 VII. 7
VIII. 8
```

### Custom symbols with restart

``` yaml
extensions:
  footnote-styles:
    custom: ["★", "◆", "●"]
    cycle: "restart"
```

In Markdown:

``` default
This^[1] is^[2] a^[3] sentence^[4] with^[5] lots^[6] of^[7] notes^[8] in it.
```

In the text:

> This<sup>★</sup> is<sup>◆</sup> a<sup>●</sup> sentence<sup>★</sup>
> with<sup>◆</sup> lots<sup>●</sup> of<sup>★</sup> notes<sup>◆</sup> in
> it.

In the notes:

``` default
★ 1
◆ 2
● 3
★ 4
◆ 5
● 6
★ 7
◆ 8
```

### Padded numbers with separator starting at 3

``` yaml
extensions:
  footnote-styles:
    style: "numeric-02"
    separator: ")"
    start-at: 3
```

In Markdown:

``` default
This^[1] is^[2] a^[3] sentence^[4] with^[5] lots^[6] of^[7] notes^[8] in it.
```

In the text:

> This<sup>03</sup> is<sup>04</sup> a<sup>05</sup> sentence<sup>06</sup>
> with<sup>07</sup> lots<sup>08</sup> of<sup>09</sup> notes<sup>10</sup>
> in it.

In the notes:

``` default
03) 1
04) 2
05) 3
06) 4
07) 5
08) 6
09) 7
10) 8
```

## Format support

Every Quarto format handles footnotes differently, and not every format
supports every possible extension options.

| Feature                         | HTML | LaTeX/PDF | Typst |
|---------------------------------|------|-----------|-------|
| All `style` options             | Yes  | Yes       | Yes   |
| `custom` symbols                | Yes  | Yes       | Yes   |
| `cycle` modes                   | Yes  | Yes       | Yes   |
| `start-at`                      | Yes  | Yes       | Yes   |
| `marker-prefix`/`marker-suffix` | Yes  | Yes       | Yes   |
| `text-prefix`/`text-suffix`     | Yes  | No        | No    |
| CSS customization               | Yes  | —         | —     |

- **HTML**: Full support. The filter replaces Pandoc’s default footnote
  rendering with custom markers and uses CSS Grid for alignment in the
  footnotes section.

- **LaTeX/PDF**: Injects `\renewcommand{\thefootnote}{...}` into the
  preamble. Simple styles (`alpha-lower`, `roman-upper`, etc.) use
  native LaTeX counter formats. Complex styles (`symbols`, `asterisk`,
  `custom`) generate a `\ifcase` lookup table. Requires the XeLaTeX or
  LuaLaTeX engine for Unicode symbols (use `pdf-engine: xelatex` [in the
  YAML](https://quarto.org/docs/output-formats/pdf-engine.html#alternate-pdf-engines)).

- **Typst**: Injects `#set footnote(numbering: ...)` into the document
  header. Simple styles map to Typst’s built-in numbering patterns.
  Complex styles use custom numbering functions.

## Customizing CSS

The extension injects minimal CSS for marker alignment. You can override
any of it in your own stylesheet or with Quarto’s `css` option:

``` yaml
format:
  html:
    css: custom.css
```

Main selectors to worry about:

- `.footnotes ol`: The footnote list container (uses CSS Grid)
- `.footnotes li::before`: The marker pseudo-element (right-aligned)
- `.footnotes li > div`: The footnote body wrapper
- `column-gap` on `.footnotes ol`: Space between marker and text
  (default: `0.4em`)
