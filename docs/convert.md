# Converting

`paginel-text convert` converts one document, with the same engine as the Paginel app. The output's
extension chooses the format.

```sh
paginel-text convert report.docx report.pdf        # Word → PDF
paginel-text convert report.docx report.md         # Word → Markdown
paginel-text convert notes.md notes.docx           # Markdown → Word
paginel-text convert notes.md notes.pdf            # Markdown → PDF
paginel-text convert export.pdf export.md          # PDF → Markdown (PDFs with real text)
paginel-text convert report.docx report.pdf --pdfa # PDF/A (archiving)
```

| From ↓ to → | `.pdf` | `.md` | `.docx` | `.txt` |
|---|---|---|---|---|
| `.docx` `.dotx` `.docm` `.dotm` | ✓ | ✓ | ✓ (rewritten) | ✓ |
| `.md` `.markdown` | ✓ | ✓ | ✓ | ✓ |
| `.txt` | ✓ | ✓ | ✓ | ✓ |
| `.pdf` | ✓ | ✓ | ✓ | ✓ |

## Markdown input

The Markdown is Paginel's: CommonMark with GitHub's tables, task lists and footnotes, the inline HTML
of [Markdown values](markdown-values.md), the picture titles of [Pictures](images.md), the
[table notation](tables.md#paginels-table-notation), and a **front matter** for the page:

```markdown
---
paper: A4
orientation: landscape
margins: 20
header: "**Example Ltd** — Annual report"
header-align: right
footer: "Page {PAGE} of {PAGES}"
footer-align: center
background: images/letterhead.png
title: Annual report
author: Jordan Lee
lang: en-GB
---
```

| Key | Values |
|---|---|
| `paper` (or `papersize`, `format`) | `A3`, `A4`, `A5`, `Letter`, `Legal` |
| `orientation` | `portrait`, `landscape` |
| `margins` (or `margin`) | one value (all sides), two (top and bottom, left and right) or four (top, right, bottom, left). A bare number is in **millimetres**; `mm`, `cm`, `in`, `pt` also work |
| `margin-top`, `margin-right`, `margin-bottom`, `margin-left` | one side |
| `header`, `footer` | Markdown; several paragraphs in a double-quoted value with `\n\n` between them, each after the first preceded by `<!-- align: … -->` when it is not on the left; `{PAGE}` and `{PAGES}` are the page number and the page count |
| `header-align`, `footer-align` | the first paragraph's alignment: `left`, `center`, `right`, `justify` |
| `background` | a picture behind every page (a path, or a Markdown image); `background-fit: contain` keeps its proportions, otherwise it is stretched to the page |
| `title`, `author`, `lang` (or `language`) | the document's properties |

One key per line, `key: value`; values may be quoted; a line starting with `#` is ignored. Note the
units: in the front matter a bare number is in millimetres, in picture titles and tables it is in
points.

Local pictures are read **relative to the Markdown file's folder**; absolute paths work too. Web
addresses (`![…](https://…)`) are never downloaded: they become grey “image to provide” frames, with
a warning (an HTML `<img src="…">` is not read at all: it is left out, with no frame and no warning):

```text
notes.md: image “https://example.org/x.png” not read (network address: never downloaded, give a file): grey “image to provide” frame
```

## Word output

A `.docx` made from Markdown or PDF uses Paginel's default styles (headings, lists, tables). To get
**your** styles, fill your own template instead: put `{{body}}` in it and run
`paginel-text fill template.docx out.docx --set body=@notes.md` (see
[the recipe](recipes.md#your-company-template-from-markdown)).

Converting a `.docx` to `.docx` rewrites it from what Paginel understood. To keep a Word file intact
while changing its text, use `save` below, or `fill`.

## PDF output

- Laid out by Paginel's engine, page for page as in the app's PDF view.
- Fonts: those built into `paginel-text` (Carlito for Calibri, Liberation Sans, Serif and Mono for
  Arial, Times New Roman and Courier New, and a few more) and the fonts the `.docx` embeds. Other
  fonts are replaced by the closest built-in one; `paginel-text info file.docx` says which
  (`fonts Calibri → Carlito`). See [Limitations](limitations.md#pdf-output).
- `--pdfa` makes a PDF/A: 2a when the document allows it (tagged, every picture with an alternative
  text), otherwise 2b; the level reached is printed (`report.pdf: PDF/A-2b`). `--pdfa=2a` or
  `--pdfa=2b` asks for one level; `--pdfa=2a` fails when it cannot be met.

## PDF input

A PDF is read back into paragraphs, headings, lists, tables and pictures, with their colours and
fonts as Markdown HTML. It works best with PDFs made by a word processor (with real text); a scanned
PDF has no text to read. Warnings say what was not understood.

## Plain text

`.txt` input: each line becomes a paragraph (an empty line, an empty paragraph). `.txt` output: the text, a paragraph per line, table
cells separated by tabs.

## Editing a Word file as Markdown

`save` writes changes made in Markdown back into the original Word file, keeping everything you did
not change (styles, comments, fields, headers…):

```sh
paginel-text convert contract.docx contract.md      # 1. to Markdown
$EDITOR contract.md                                 # 2. change the text (or let a program do it)
paginel-text save contract.docx contract.md contract-v2.docx   # 3. back into the .docx
```

The report says how many blocks were kept, patched and rewritten:

```text
blocks kept 19, patched 1, rewritten 0, unrecognized 0; parts rewritten: word/document.xml
```
