# Where placeholders work

`paginel-text fill` and `paginel-text fields` walk the same parts of a template. Run
`paginel-text fields template.docx` to see where each placeholder was found (`[body]`, `[header]`,
`[first-header]`, `[table]`, `[footnote]`…), and which ones it will not fill (`[endnote]`, `[comment]`,
`[field-code]`, marked *not filled there*).

| Part of the document | Values | Loops | Notes |
|---|---|---|---|
| Body paragraphs | inline and block | inline, paragraphs, rows | |
| Table cells (and tables in cells) | inline and block | inline, paragraphs of the cell, rows | |
| Headers and footers: default, first page, even pages | inline and block (paragraphs, lists) | inline, paragraphs | tables flattened, with a warning |
| Headers and footers of every section, not only the last | as above | as above | |
| Tables inside a header or footer | inline and block | inline, paragraphs of the cell | row loops refused with a clear error |
| Footnotes | inline and block (paragraphs, lists) | inline, paragraphs | a note referenced inside a loop is filled once per copy |
| Text boxes | inline and block | inline, paragraphs | a footnote mark in a value is dropped, with a warning |
| Content controls (Word forms) | inline and block | inline, paragraphs | the control is kept around the value |
| Hyperlinks | the text of a link | | addresses are filled too, as plain text (values only, not sections) |
| Front matter of a `.md` template | `header:` and `footer:` | | |

## The body and tables

Everything on the other pages applies. In a table cell, a placeholder alone in its paragraph is a
block placeholder; the cell keeps its width, shading and borders, and pictures sized in `%` take the
cell's width.

## Headers and footers

- The default header and footer, the **first-page** ones (*Different First Page*) and the
  **even-page** ones (*Different Odd & Even Pages*) are all filled, in every section of the document.
- In a header or footer, a block value may hold paragraphs and lists; its paragraphs take the style
  of the placeholder's paragraph (usually *Header* or *Footer*), so tab stops still apply, and its
  list items are Word list paragraphs (*List Paragraph*). A table in such a
  value is flattened into paragraphs (tabs between cells), with a warning. A footnote mark is
  dropped, with a warning.
- A paragraph that the data leaves empty (a placeholder alone whose value is missing or empty, or a
  line of sections that are all false) **stays, empty**, in a header or footer: a missing value leaves
  an empty line there. In the body, such a paragraph is removed.
- Pictures work: a logo in the header is the most common case
  ([Pictures](images.md#pictures-in-headers-and-footers)).
- **Tables inside a header or footer** (a “logo | address” layout): values in their cells are filled.
  A value that is only a list, in a header table cell, stays in its own cell, and paragraphs of a
  cell can be repeated (`{{#items}}`, a paragraph, `{{/items}}`, all in the cell). Rows cannot be
  repeated there: a row loop in a header table is refused with a clear message (put the row loop in
  the body). A block loop over a whole table in a header gives one table per item (except a table of
  one cell holding one paragraph: see [Limitations](limitations.md#where-placeholders-are-found)).
  A header table that holds another table is filled in place, both tables kept; the inner table is
  lost only when a false block section empties one of its cells
  ([Limitations](limitations.md#where-placeholders-are-found)).
- Fields (`PAGE`, `NUMPAGES`) and pictures of a header that `paginel-text` does not touch are copied
  as they are.

## Footnotes

Tags in the template's footnotes are filled. A footnote whose reference is inside a loop is filled
**once per copy**, with that copy's data: `Chapter {{title}}` with a note `Note for {{title}}.` gives
*Note for One.* and *Note for Two.* When a loop has no item, the notes it referenced are dropped and
their tags are not reported as missing.

Footnotes written in Markdown values (`[^1]`) become new footnotes, numbered after the template's own.

## Text boxes

Placeholders in a Word text box (*Insert › Text Box*, or a shape with text) are filled like those in
the body: inline values, block values, loops over the box's paragraphs. A block value placed in a text
box stays entirely inside the box, headings, lists and tables included; a paragraph that anchors a
text box is never removed, even when its value is missing. Word has no footnotes in a text box: a
footnote in a value placed there is left out, with a warning (“footnote of … in a header, a footer,
a note or a text box, where Word has none: left out”), as in headers. Pictures in a text box and
text boxes anchored on a section tag's paragraph have limits: see
[Limitations](limitations.md#word-features-around-placeholders).

## Content controls

Word forms often wrap a placeholder in a content control (*Developer › Plain Text Content Control*).
The value is written **inside** the control, which keeps its properties (title, tag, lock), as when
you type in it in Word; a data binding or a placeholder-text state is removed, so that Word shows
the value. The same holds for custom XML, smart tags, tracked insertions and simple fields around a
placeholder. A wrapper that the value only partly covers is removed, its text kept
([Limitations](limitations.md#word-features-around-placeholders)).
Word's *Repeating Section* control around table rows keeps the table's style when its rows are
repeated, and each copied row gets its own control. A block loop over paragraphs wrapped in a
content control gives one control per item.

## Hyperlinks

- A placeholder inside the **text** of a template's hyperlink is filled, and the value stays part of
  the link.
- A placeholder in the **address** of a hyperlink (`mailto:{{email}}`, `https://example.org/orders/{{id}}`)
  is filled with the value as plain text, in a link typed in Word as in a `HYPERLINK` field. A
  section (`{{#…}}`) there is not filled: a warning, and an error with `--strict`.
- A link in a value (`[text](https://example.org)`) inside a template link becomes a link of its own
  next to it (Word has no links inside links).
- Addresses from the data are written as given, whatever their scheme: check them if the data is not
  trusted.

## A Markdown template's front matter

In a `.md` template, placeholders in the front matter's `header:` and `footer:` are filled:

```markdown
---
header: "**{{organisation}}** — meeting report"
footer: "Page {PAGE} of {PAGES}"
---
```

`{PAGE}` and `{PAGES}` (single braces) are page fields, not placeholders.

## Not reached

| Where | What happens |
|---|---|
| **Endnotes** | not filled, left as typed; a warning (“tag not filled in this place (not supported)”), listed by `fields` as *not filled there*, an error with `--strict` |
| **Field instructions** (a tag inside a `MERGEFIELD` or `IF` field code) | same as endnotes |
| **Comments** (*Review › New Comment*) | same as endnotes |
| **Document properties** (*File › Info*: title, author…) | not filled |
| A picture's **alternative text**, a chart's data, SmartArt, embedded objects | not filled |
| A tag inside a picture path in a `.md` template (`![]({{x}})`) | not replaced: put the whole picture in the value |
| Word's own mail-merge fields (`«Name»`) | not read: they are fields, not tags |
