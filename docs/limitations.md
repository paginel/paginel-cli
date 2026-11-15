# Limitations

What `paginel-text` does not do, or not yet. Each point was checked against the binary; the ones
that depend on the Word file's inner structure were checked with hand-made Word packages. If one
of these blocks you, tell us ([issues](https://github.com/paginel/paginel-cli/issues) or
hello@paginel.com): it helps us choose what comes next.

- [Template syntax](#template-syntax)
- [Where placeholders are found](#where-placeholders-are-found)
- [Word features around placeholders](#word-features-around-placeholders)
- [Values](#values)
- [Templates](#templates)
- [Data and sizes](#data-and-sizes)
- [PDF output](#pdf-output)
- [Platforms](#platforms)
- [Other](#other)

## Template syntax

- A Mustache **subset**: no partials (`{{> name}}`), no lambdas, no delimiter changes
  (`{{=<% %>=}}`). They are left as text, with a warning (an error with `--strict`).
- No expressions: no comparisons, no arithmetic, no number or date formatting, no filters, no
  “first”, “last” or “index” in loops. Prepare the values in the program that writes the data.
- `true` and `false` are written as `true` and `false`. Numbers are normalised (`19.90` → `19.9`,
  `1e3` → `1000`, `2e15` → `2000000000000000`); a whole number from 10^16 up keeps an exponent
  (`1e16` → `1e+16`, `1e300` → `1e+300`). To print a number your way, send it as a string.
- A placeholder cannot span two paragraphs: `{{na` at the end of one paragraph and `me}}` at the
  start of the next are left as typed, with a warning (“looks like a tag but is not one”).
- Names: at most 32 segments (`a.b.c…`), sections nested at most 32 deep. Beyond, the template is
  refused (“a key has at most 32 segments”, “nested more than 32 levels deep”, exit code 1).
- Unicode keys are compared after NFC normalisation: a key typed in Word with a combining accent
  matches the same key typed with a single accented letter. Two data keys that differ only in this
  way are one key: one of the two values is kept, the other dropped, without a warning.
- Two sections that cross each other across paragraphs, or within one paragraph of a table cell,
  give two errors instead of one (“comes while … is open”, then “is never closed”): the first is
  the right one.

## Where placeholders are found

Found: the body, table cells, text boxes, content controls, headers and footers of every kind and
every section, footnotes, hyperlink text and addresses, a `.md` template's front matter
([Where placeholders work](where-tags-work.md)).

Not found:

- **endnotes**, **comments** and **field codes** (a tag inside a `MERGEFIELD` or `IF` field's
  instruction): left as typed; a warning says the tag is not supported there (“tag not filled in
  this place (not supported)”), `fields` lists it as *not filled there*, and `--strict` fails. (A tag
  in a `HYPERLINK` field's address is filled, like any link address.)
- a **section** (`{{#…}}`) in a link address: not filled, with the same warning;
- **document properties** (*File › Info*), alternative texts, charts, SmartArt, embedded objects:
  left as they are, without a warning (keys used only there are reported as *data keys not used*);
- a tag inside a picture path of a `.md` template (`![]({{x}})`): the picture is looked for under
  that name, and the grey “image to provide” frame takes its place, with a warning. Put the whole
  picture in the value (`{{logo}}` with `![Logo](logo.png)`).

In headers and footers:

- a **table** in a value is flattened into paragraphs (tabs between cells); a footnote mark in a
  value is dropped. Both with a warning;
- a paragraph that the data leaves **empty** (a placeholder alone whose value is missing or empty)
  stays, as an empty line; in the body it is removed. Give the value, or put an optional value on a
  line that has other text;
- **table rows** cannot be repeated in a header or footer table: the template is refused (“In a
  header or footer, table rows are not repeated (not supported): a row loop goes in the body”). Put
  the row loop in the body;
- a block loop over a whole table in a header gives one table per item, except for a table of a
  single cell holding a single paragraph: its copies all go into that one cell;
- a header table that holds another table keeps it, except when a block section that is false
  (`{{#flag}}` and `{{/flag}}` alone in their paragraphs) empties a cell of the inner table: the
  inner table is then lost. Write that section within one paragraph (`{{#flag}}…{{/flag}}`): the
  table stays.

## Word features around placeholders

`paginel-text` copies byte for byte everything it does not change. Around the paragraphs it changes:

- **A content control, custom XML, a smart tag or a tracked insertion around a placeholder** stays,
  with the value inside it, unless the change reaches past it. It is then removed and its text kept:
  when it holds only part of a placeholder (the `{{` outside it and the `}}` inside, say), or when the
  placeholder in it is directly followed by another placeholder of the paragraph (`{{name}}` in a
  control, then `{{date}}` right after it).
- **A check box content control** between two placeholders of a paragraph, or inside a section
  repeated within the line, becomes a plain ☐ or ☒ character. Before or after the paragraph's
  placeholders, it stays a check box.
- **A value of several paragraphs in a block content control**: each paragraph gets a control of
  its own, all with the same tag (the text is right).
- **A content control repeated by a loop that has a loop inside it**: the items share one control.
- **A loop over zero items around a content control** (around paragraphs or table rows): an empty
  control stays. The file is valid; LibreOffice shows nothing there.
- **A bookmark or a comment on a section tag's paragraph** (`{{#items}}` inside a bookmark, a
  cross-reference target for example): that paragraph stays, empty, and so can the tag paragraphs of
  the document's other block loops: empty lines appear. Word's own hidden `_GoBack` bookmark does not
  do this. Move the bookmark or the comment to another paragraph.
- **Section breaks and loops**: a section break on the **closing** tag's paragraph (`{{/chapters}}`
  followed by a section break) ends the section that holds the whole loop: it is not repeated per
  item, and with no items that section stays, as an empty page if nothing else is in it. To repeat a
  section per item, put the break inside the loop, on the last paragraph before `{{/chapters}}`. A
  loop over zero items removes the section breaks inside it (with a warning); the content before the
  loop in the same section then takes the page setup of the section after it.
- **Text boxes**:
  - a picture value in a text box: Word 2010 and later show it; the older drawing kept for Word 2007
    and some converters shows the filled text without the picture;
  - a footnote in a value placed in a text box is left out, with a warning (Word has no notes
    there). Text boxes are recognised by their text, so a body paragraph with the same text as a
    paragraph of a text box loses its notes too, with the same warning;
  - a text box anchored on a **section tag's** paragraph (`{{#items}}`): its text is repeated into the
    body, or emptied for zero items. Anchor text boxes on other paragraphs.
- **Tracked changes** in repeated content are copied with each item (with new revision ids); accept
  or reject tracked changes in Word before using a file as a template.

## Values

- **A list value** takes the placeholder's formatting: its first item keeps every detail of it; the
  next items take the visible format (bold, italic, colour, size, font name) but not theme fonts,
  character spacing, scale, kerning or language, and a shading becomes a highlight.
- **Alt text** of pictures is not carried to Word: pictures added by `paginel-text` have no *Alt
  Text*. So `--pdfa=2a` fails on documents with such pictures (“PDF/A not possible: an image has no
  alternative text”); `--pdfa` gives PDF/A-2b.
- **SVG** pictures are not supported (Word needs a bitmap): Word shows the grey “image to provide”
  frame, with a warning. Convert them to PNG. BMP, EMF, WMF, HEIC and PDF neither.
- **Web pictures** (`![…](https://…)`) are never downloaded: grey frame, with a warning. An HTML
  `<img src="…">`, local or web, is not read at all: it is left out, with no frame and no warning,
  and `--strict` does not catch it. Write `![alt](path)`.
- A **Markdown table** in a value does not take a Word table style (it gets a thin grid, or what
  Paginel's [table notation](tables.md#paginels-table-notation) says), and spans the text width. Use a
  [template table with repeated rows](tables.md#2-a-template-table-with-repeated-rows) for styled
  tables.
- A Markdown table value placed in a **cell of a template table** becomes a nested table whose width
  is an equal share of the outer table (its width divided by its number of columns): with uneven
  columns it can be narrower or wider than its cell.
- A `data:` picture (the scheme in any case: `data:`, `DATA:`) that is not a base64 PNG, JPEG, GIF,
  WebP or TIFF is left out (no grey frame), with a warning. A `data:` SVG gets the grey frame, like an
  SVG file.
- A table in an inline value, or in a header, footer or footnote, is flattened into text (one line
  per row, tabs between cells), with a warning.
- A numbered list in a value always starts its own numbering; it cannot continue a list of the
  template.
- Task lists (`- [ ]`) give ☐ and ☒ characters, not Word check boxes.
- Links in values are written as given, whatever their scheme: check untrusted data.

## Templates

- `.docm` and `.dotm`: the result is a `.docx`, **without the macros** (a warning says so).
- A `.md` template produces a Word document with Paginel's default styles, not a company's. Use a
  Word template for that ([recipe](recipes.md#your-company-template-from-markdown)).
- Word's *Repeating Section* content control around table rows: supported, one control per copied
  row.

## Data and sizes

- JSON only: no YAML, no CSV (convert CSV with a one-liner, see the
  [recipe](recipes.md#from-a-csv-file)).
- `--set` values are strings; `--set` cannot change an item of a list given in the data
  (`--set team.0.name=…` is refused, exit code 2): give the list in the JSON.
- Data: 50 MiB at most, objects and lists nested at most 127 deep. Pictures: 20 MiB each. Lists:
  100 000 items. A filled document: 1 000 000 blocks and 50 million characters; repetitions within
  lines: 500 000.
- Very large formatted values repeated many times (for example 100 items, each with a 900 KB
  formatted value) can use several GB of memory.
- A paragraph of tens of thousands of runs (for example a template where every character is a
  separate run) is slow to read: about a minute for 40 000 runs.

## PDF output

- The PDF is laid out by Paginel's own engine, not by Word: line and page breaks are close to Word's,
  not always identical. On the five examples, the page count is the same as Word's and LibreOffice's.
  Lists are less indented and table cells are tighter than in Word. The `.docx` is what Word shows.
- Fonts: only the fonts built into `paginel-text` and the fonts embedded in the `.docx`. Calibri
  becomes Carlito and Arial, Times New Roman and Courier New become Liberation Sans, Serif and Mono
  (same widths); any other font (your corporate font, for example) is replaced by one of these.
  `paginel-text` never reads the fonts installed on your system. `paginel-text info template.docx`
  shows the replacements. To keep a special font, embed it in the template (Word: *File › Options ›
  Save › Embed fonts in the file*) if its licence allows it, or make the PDF with Word or LibreOffice
  from the filled `.docx`.

## Platforms

- macOS: no build in version 0.3.0. It comes in a later version, for Apple silicon.
- Linux: x86_64 with glibc 2.35 or later (Ubuntu 22.04, Debian 12, Fedora 36 and later). Not
  Alpine (musl), not RHEL 9 or its rebuilds (glibc 2.34), not ARM yet.
- Windows: x86_64 only (checked on Windows 10).
- The Windows binary is not signed by Microsoft during the beta: Windows warns the first time (see
  [Troubleshooting](troubleshooting.md#installation)).

## Other

- One output per run: to make many, loop in your shell or your program ([recipes](recipes.md)).
- The template is read from a file, not from standard input.
- No configuration file; no networking code: web pictures are never downloaded. A path to a network
  share is opened like any file ([Privacy](../README.md#privacy-works-offline)).
