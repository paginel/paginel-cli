# Pictures

A picture is a Markdown image in a value:

```markdown
![Alt text](images/chart.png "width 50%")
```

- the **path** says which file;
- the **title** (in quotes, optional) says how big and where, with the same words as the Paginel app.

[examples/02-images](../examples/02-images/) shows the common cases in one document. Every size on
this page was measured in the `.docx` written by `paginel-text`, on an A4 page with 2.5 cm margins
(16 cm of text width), from a 192 × 96 pixel PNG.

- [Where pictures are read from](#where-pictures-are-read-from)
- [Formats](#formats)
- [Size](#size)
- [Placement](#placement)
- [Pictures in tables](#pictures-in-tables)
- [Pictures in headers and footers](#pictures-in-headers-and-footers)
- [When a picture cannot be used](#when-a-picture-cannot-be-used)

## Where pictures are read from

Relative paths are read from the **base folder**:

| The value comes from | Base folder |
|---|---|
| a JSON file (`data/values.json`) | the folder of that file (`data/`) |
| standard input (`-`) | the current folder |
| a pipe or process substitution as DATA (`<(jq … data.json)`) | the current folder |
| `--set key=…` with a JSON file | the folder of the JSON file |
| `--set key=…` without a JSON file | the current folder |
| `--set key=@notes.md` | the folder of `notes.md`, always (even with `--base`) |
| any of the first five, with `--base DIR` | `DIR` |
| a `.md` **template**'s own pictures | the template's folder ([below](#pictures-of-a-markdown-template)) |

```sh
# pictures in data/values.json are read from data/
paginel-text fill letter.docx data/values.json out.docx
# the same JSON on standard input: read from the current folder…
cat data/values.json | paginel-text fill letter.docx - out.docx
# …unless you say where
cat data/values.json | paginel-text fill letter.docx - out.docx --base data
```

For safety, because data is often written by programs or AI agents:

- **absolute paths** (`/home/me/logo.png`, `~/logo.png`, `//server/logo.png`) are refused;
- paths that **leave the base folder** (`../secret.png`, or a symbolic link inside the base folder that
  points outside) are refused. Paths are resolved (`..`, `%2e%2e`, symbolic links) before the check;
- `--allow-any-path` lifts both rules, when you trust the data. A path to a network share (on
  Windows, `\\server\share\logo.png` or `//server/share/logo.png`) is then opened like any file, so
  your operating system fetches it from that share;
- **web addresses** (`https://…`) are **never** downloaded, even with `--allow-any-path`:
  `paginel-text` has no networking code and never opens a network connection itself
  ([Privacy](../README.md#privacy-works-offline));
- an HTML `<img src="…">` is not read at all, local or web: it is left out, with no frame and no
  warning. Write `![alt](path)`;
- a picture file larger than 20 MiB is refused.

A refused, missing or unreadable picture becomes the grey “image to provide” frame
([below](#when-a-picture-cannot-be-used)) and the report shows a warning.

**Paths with spaces** are written `<my picture.png>` (angle brackets) or `my%20picture.png`.

**`data:` addresses** are read too, for programs that prefer to put the bytes in the JSON:

```json
{ "logo": "![Logo](data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAA… \"height 1cm\")" }
```

The `data:` prefix may be written in any case (`DATA:`, `Data:`). An SVG one gives the grey frame
and a warning, like an SVG file. One that is not a base64 PNG, JPEG, GIF, WebP or TIFF picture is
**left out** (no grey frame), with a warning (`invalid_data_uri`). Both fail `--strict`.

### Pictures of a Markdown template

A `.md` template's own pictures (`![](logo.png)` typed in the template, not in a value) are read like
`paginel-text convert` reads them: relative to the template's folder, and absolute paths are allowed,
since the template is your own file; a path to a network share (`//server/share/logo.png`) is opened
like any file too, and on Windows your operating system fetches it from that share. `data:` addresses
work there too. Web addresses are never downloaded. A missing picture, or a web one, gives the grey
frame and a warning, and fails `--strict`:

```text
warning: image “images/missing.png” of the template not read (file not found: /home/me/tpl/images/missing.png): grey “image to provide” frame
```

## Formats

| Format | |
|---|---|
| PNG, JPEG, GIF, WebP | copied into the `.docx` as they are |
| TIFF | converted to PNG |
| SVG | **not supported**: Word needs a bitmap; you get the grey frame and a warning (an error with `--strict`). Convert it to PNG first, for example `rsvg-convert -w 1200 logo.svg -o logo.png` |
| BMP, EMF, WMF, HEIC, PDF, anything else | not supported: grey frame and a warning (“not a PNG, JPEG, GIF, WebP, TIFF or SVG image”) |

The format is recognised from the file's **content**, not from its extension: a PNG named `.jpg` is
read as a PNG.

## Size

| Title | Measured size of the 192 × 96 px picture |
|---|---|
| *(no title)* | natural size at 96 dots per inch: 5.08 × 2.54 cm; reduced to the text width if larger (a 2400 px wide picture: 16 × 8 cm) |
| `"width 5cm"` | 5 × 2.5 cm (height in proportion) |
| `"width 50mm"` | 5 × 2.5 cm |
| `"width 50%"` | 8 × 4 cm: half the text width |
| `"height 2cm"` | 4 × 2 cm (width in proportion) |
| `"width 6cm; height 2cm"` | 6 × 2 cm (both given: proportions not kept) |
| `"120x40"`, `"120 x 40pt"` | 4.23 × 1.41 cm: 120 × 40 points |
| `"inline; width 2cm"` | 2 × 1 cm, in the line (`inline` is the default) |

- Units: `pt` (also a bare number), `mm`, `cm`, `in`. The decimal separator is a dot: `5.5cm`, not
  `5,5cm`. A length is at most 22 inches (Word's limit for a picture's side); a width in `%` at most
  1000%.
- Words are not case-sensitive: `"Width 40%"` works.
- **What 100% is**: the width of the text where the picture lands. In the body, the page's width
  minus its margins, for the section the picture is in. **In a table cell of the template, the cell's
  width** (minus its padding): a `width 60%` picture in a 5 cm column is 2.77 cm wide.
- In a cell of a **Markdown table** (a table that is itself a value), `%` is a percentage of that
  cell's width, and a larger picture is reduced to fit the cell. A Markdown table placed in a cell
  of a template table is the exception: see
  [Tables](tables.md#what-a-markdown-table-does-not-do).

If a title is not understood (`"large"`, `"width 5,5cm"`, `"wrap around"` without a place), the
picture keeps its natural size and the report warns:

```text
warning: image title “width 5,5cm” of badtitle2 not understood (size or placement, e.g. "width 5cm", "right; width 40%"): natural size (body, block 26: “badtitle2: {{badtitle2}}”)
```

The title is a setting only when **every** item in it is understood; otherwise it is an ordinary
title and nothing of it applies.

## Placement

By default a picture is **inline**: it sits in the line like a big letter. Alone in a paragraph, it
follows the paragraph's alignment (centre the placeholder's paragraph in Word to centre the picture).

A placement makes it **float**, with text wrapping around it. Items are separated by `;`, in any
order: `"right; width 40%; gap 6pt"`.

| Title | Word receives (measured) |
|---|---|
| `"right; width 35%"` | aligned right in the text column, top of the paragraph, square wrapping: text on its left |
| `"left; width 4cm"` | aligned left, square wrapping |
| `"center"` | centred in the column, text above and below |
| `"top"`, `"bottom"` | centred at the top or the bottom of the margins, text above and below |
| `"behind"` | behind the text, no wrapping, centred in the column (a watermark) |
| `"behind; page 0 0; width 100%"` | behind the text, at the page's top-left corner, as wide as the text |
| `"page 2cm 3cm"` | 2 cm from the page's left edge, 3 cm from its top, square wrapping |
| `"margin 0 0"` | at the top-left corner of the margins |
| `"x margin right; y page 2cm"` | right edge of the margins, 2 cm from the top of the page |
| `"y paragraph 1cm"` | 1 cm below the top of its paragraph, at the column's left edge |
| `"right; wrap above-below"` | on the right, no text beside it |
| `"left; wrap none"` | on the left, text runs over it |
| `"right; gap 12pt"` | 12 points between the picture and the text; `gap 6pt 12pt` (vertical, horizontal) or four values (top, right, bottom, left) |
| `"right; rotate 90"` | turned 90° (degrees, `90deg` works too) |
| `"left; flip h"`, `"left; flip h v"` | mirrored horizontally, and vertically |

The vocabulary:

- **at most one placement word**: `inline`, `left`, `right`, `center`, `top`, `bottom`;
- `behind`: behind the text;
- **positions**: `page X Y`, `margin X Y` (from the page's or the margins' top-left corner);
  `x page|margin|column P` and `y page|margin|paragraph P`, where `P` is a length or `left`, `center`,
  `right` for `x`, `top`, `center`, `bottom` for `y` (`y paragraph` takes a length only);
- **settings**: `width L` (or `%`), `height L`, `wrap around|above-below|none`, `gap L…`,
  `rotate DEG`, `flip h|v`.

Wrapping, gaps, rotation and mirroring need a place (a word, `behind` or a position): `"wrap around"`
or `"rotate 90"` alone are not understood. `inline` with a floating setting (`"inline; wrap around"`)
and two placement words (`"left; right"`) are not understood either.

**A floating picture with text beside it**, in one block value:

```markdown
![The workshop](images/workshop.png "right; width 35%")
Our new workshop is twice as large as the old one…

You are welcome to visit on the first Saturday of each month…
```

The picture belongs to the paragraph that follows it on the next line (no blank line between them);
the text of that paragraph and the next ones wraps around it.

## Pictures in tables

**In a template table**, put the placeholder in a cell. `width N%` is a percentage of that cell's
width:

| Product | Picture | Price |
|---|---|---|
| `{{#products}}{{name}}` | `{{photo}}` | `{{price}}{{/products}}` |

```json
{ "products": [ { "name": "Mug", "photo": "![Mug](images/mug.png \"width 60%\")", "price": "18.00" } ] }
```

**In a Markdown table value**, a picture in a cell works too: `| ![](logo.png "width 2cm") | Logo |`
(see the note on `%` [above](#size)).

## Pictures in headers and footers

A logo in the header is the most common case:

```text
Header of the template:   {{logo}}  ⇥  Annual report
```

```json
{ "logo": "![Company logo](images/logo.png \"height 1cm\")" }
```

Transparent PNGs keep their transparency. A logo that never changes is better **in the template
itself** (insert it in Word): `paginel-text` keeps the template's own pictures as they are, crop and
alternative text included, even in a header paragraph that also holds a placeholder.

## When a picture cannot be used

The picture is replaced by a grey “image to provide” frame (240 × 135 points, 8.47 × 4.76 cm; an SVG
keeps its own size), and the report says why, with the path as written in the value:

| Cause | Warning (English) | JSON `problem` |
|---|---|---|
| file missing | `image “images/nope.png” of photo not read (file not found: /home/me/data/images/nope.png): grey “image to provide” frame` | `not_found` |
| a folder, a pipe, a device | `… (not a regular file (folder, pipe, device): /home/me/data/images) …` | `not_a_file` |
| absolute path | `… (absolute path refused (--allow-any-path to accept it)) …` | `absolute_path` |
| outside the base folder | `… (outside the base folder /home/me/data, refused (--base, or --allow-any-path)) …` | `outside_base` |
| web address | `… (network address: never downloaded, give a file) …` | `remote` |
| larger than 20 MiB | `… (file larger than 20 MiB) …` | `too_large` |
| not a picture, BMP… | `… (not a PNG, JPEG, GIF, WebP, TIFF or SVG image) …` | `not_an_image` |
| a `data:` address that is not a picture | `image “data:image/png;base64,…” of photo not read (data: address that is not a base64 PNG, JPEG, GIF, WebP or TIFF image): left out` | `invalid_data_uri` |
| SVG | `SVG image “images/a.svg” of photo: Word shows the grey “image to provide” frame instead; give a PNG` | code `svg_image` |

Each warning ends with its place in the template, as in
`warning: image “images/nope.png” of photo not read (file not found: /home/me/data/images/nope.png): grey “image to provide” frame (body, block 1: “{{photo}}”)`.
The path after “file not found” is the one that was tried, so you can see which base folder was
used.

With `--strict`, any of these stops the fill: exit code 3, nothing written.

## Alt text

Word's alternative text (*Alt Text*) is not filled from the Markdown `![alt]`: pictures added by
`paginel-text` have none. Because of that, `--pdfa=2a` (accessible PDF/A) fails on a document with
such pictures; `--pdfa` alone falls back to PDF/A-2b. This is a [known limitation](limitations.md).
