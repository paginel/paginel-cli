# Markdown values

Every value is Markdown, read by the same parser as the Paginel app: CommonMark, with GitHub's
tables, task lists, strikethrough and footnotes, a little inline HTML, and a few additions for Word.
Use [`{{&key}}`](#plain-text-key) when a value must stay plain text.

What a value may contain depends on the placeholder's place
([inline or block](template-syntax.md#inline-or-block-where-the-placeholder-is-decides)): a
placeholder inside a sentence takes the [inline part](#inline-formatting); a placeholder alone in its
paragraph also takes [blocks](#blocks).

## Inline formatting

Works everywhere: in a sentence, alone in a paragraph, in a table cell, a header, a footer, a
footnote.

| You write | Word receives |
|---|---|
| `**bold**`, `__bold__`, `<b>bold</b>`, `<strong>…</strong>` | bold |
| `*italic*`, `_italic_`, `<i>…</i>`, `<em>…</em>` | italic |
| `***both***` | bold italic |
| `~~struck~~`, `<s>…</s>`, `<del>…</del>` | strikethrough |
| `` `code` `` | the template's inline-code character style (a monospace font) |
| `[text](https://example.org)` | a Word hyperlink, in the *Hyperlink* style |
| `<u>underlined</u>`, `<ins>…</ins>` | single underline |
| `<mark>highlighted</mark>` | yellow highlight |
| `x<sup>2</sup>`, `H<sub>2</sub>O` | superscript, subscript |
| `<span style="color:#C00000">red</span>` | a text colour (`#RGB` or `#RRGGBB`) |
| `<span style="background:#FFFF00">…</span>` | a highlight (`background` or `background-color`) |
| `<span style="font-size:14pt">bigger</span>` | a size, in `pt` or `px` |
| `<span style="font-family:Arial">Arial</span>` | a font (its first family; generic names like `serif` are ignored) |
| `<span style="text-transform:uppercase">…</span>` | all caps |
| `<span style="font-variant:small-caps">…</span>` | small caps |
| `<font color="#C00000" face="Arial">…</font>` | colour and font |
| `see[^1]` and, on its own line, `[^1]: The note.` | a Word footnote, numbered after the template's own |
| `![alt](picture.png "width 3cm")` | a picture, see [Pictures](images.md) |
| a line ending with `\`, or with two spaces, or `<br>` | a line break |
| `\*`, `\_`, `\#`, `\[`… | the character itself |

Several properties can go in one `style`: `<span style="color:#1F4E79;font-size:12pt">`.

**Spaces and newlines.** A single newline inside a paragraph is a space (CommonMark's rule):
`"first line\nsecond line"` gives *first line second line*. A blank line (`\n\n`) starts a new
paragraph. `--breaks` makes every single newline a line break, as in GitHub comments; code blocks are
not affected. Spaces and newlines at the start and the end of a value are ignored.

**Links** from the data are written as given, whatever their scheme (`https:`, `mailto:`, `file:`,
`javascript:`…). If the data comes from people or programs you do not trust, check the addresses
before filling.

## Blocks

When the placeholder is alone in its paragraph, the value can hold blocks. Each line below was filled
into a paragraph styled justified, Georgia 11 pt, dark blue, with spacing before and after, and read
back from the `.docx`.

| You write | Word receives |
|---|---|
| a single paragraph | the placeholder's own paragraph, unchanged except for its text: style, alignment, numbering, borders kept |
| several paragraphs (`\n\n` between them) | one paragraph each, with the placeholder paragraph's style, alignment, spacing, indentation and character format (justified, Georgia 11 pt, dark blue) |
| `# Title` … `###### Title` | the template's *Heading 1* … *Heading 6* (added to the file if the template lacks one) |
| `- item`, `* item`, `+ item` | a Word bullet list; items keep the placeholder's alignment, spacing and character format, the indentation comes from the list |
| `1. item` | a Word numbered list; `3.` as the first number starts it at 3 |
| nested lists (indent by 2 to 4 spaces) | nested list levels (a numbered list may nest in a bullet list and the other way round) |
| `- [ ] to do`, `- [x] done` | bullet items starting with ☐ and ☒ (characters, not Word check boxes) |
| `> quoted` | the template's *Quote* style |
| ```` ``` ```` fenced or indented code | the template's code style (added if missing), one paragraph per line; an indented block at the very start of a value is a plain paragraph, since leading spaces are ignored: fence it |
| `---` (a line alone) | an empty paragraph with a bottom border (a horizontal line) |
| a table | a Word table, see [Tables](tables.md) |
| `\newpage` alone on a line, or `<!-- pagebreak -->` | a page break |
| `<!-- align: center -->` on the line before a paragraph | its alignment: `left`, `center`, `right` or `justify` |
| an image alone on its line | a paragraph holding the picture; see [Pictures](images.md) for floating ones |
| other HTML blocks (`<div>…</div>`) | their text only |

How the blocks look:

- **Paragraphs and list items** follow the paragraph that held the placeholder (see above). So if
  `{{body}}` sits in a justified *Body Text* paragraph in Georgia 11 pt, the value's paragraphs are
  justified *Body Text* in Georgia 11 pt, and its list items are justified, in Georgia 11 pt. From
  the second list item on, only the visible character format is carried (bold, italic, colour, size,
  font name), not theme fonts, character spacing, scale, kerning or language
  ([Limitations](limitations.md#values)).
- **Headings, quotes and code blocks** use the template's styles for them. Word gives built-in styles
  a name in the template's language (*Heading 1* is *Titre 1* in a French Word): `paginel-text` finds
  them by their built-in identity, so `#` lands in the right style whatever the language.
- **A numbered list** in a value is its own list: it starts at 1 (or at the number you wrote) and
  never continues a list of the template. Two values with numbered lists give two separate lists.
- **Footnotes** in a value become Word footnotes, numbered after the template's own (a template with
  one footnote: the value's first note is 2).
- A value that is a **single plain paragraph** (no heading, list, quote, code, table) is not split
  into blocks: it goes straight into the placeholder's paragraph, which keeps its style. That is why
  `{{title}}` in a *Title* paragraph stays a title.

## Inline placeholders and block syntax

In a placeholder that shares its paragraph with other text, block syntax is not read. Results read
back from the `.docx`:

| Value | Inline result |
|---|---|
| `2024. A good year` | 2024. A good year (not a list starting at 2024) |
| `- not a list` | - not a list |
| `# not a title` | # not a title |
| `a \newpage b` | a \newpage b (no page break in a line) |
| `first\n\nsecond` (two paragraphs) | first, a line break, second |
| `<!-- c -->x` | `<!-- c -->x`, as typed |
| `[ref]: https://example.org` | `[ref]: https://example.org`, as typed |
| a table | its text, cells separated by tabs, one line per row, with a warning |

The table warning reads:

```text
warning: table of tbl where it cannot go (within a line, a header, a footer or a note): its text, one line per row (body, block 17: “tbl: [{{tbl}}] [{{&tbl}}]”)
```

## Plain text: `{{&key}}`

`{{&key}}` (or `{{{key}}}`) writes the value exactly as it is: `*`, `_`, `#`, `<` and `[` stay as
typed, and every newline is a line break. It still takes the placeholder's character format. Use it
for references, codes, file names, anything with underscores, user input you do not control.

| Data | `{{key}}` gives | `{{&key}}` gives |
|---|---|---|
| `"__init__.py"` | **init**.py (bold!) | \_\_init\_\_.py |
| `"BF_2026_*0042*"` | BF_2026_ then *0042* in italics | BF\_2026\_\*0042\* |
| `"Use <b> for bold"` | Use **for bold** (an HTML tag) | Use &lt;b&gt; for bold |
| `"5 * 3 = 15"` | 5 * 3 = 15 | 5 * 3 = 15 |
| `"line 1\nline 2"` | line 1 line 2 | line 1, a line break, line 2 |

You can also escape single characters in Markdown: the JSON string `"\\_\\_init\\_\\_.py"` is the
Markdown `\_\_init\_\_.py`, which gives `__init__.py`.

## Writing Markdown inside JSON

JSON strings need `\n` for newlines, `\"` for double quotes and `\\` for a backslash:

```json
{
  "notes": "## Next steps\n\n1. Sign the quote.\n2. Send it back **before Friday**.\n\nQuestions? Write to [our team](mailto:hello@example.org).",
  "logo": "![Logo](images/logo.png \"height 1.5cm\")"
}
```

Long Markdown is easier in its own file: `--set notes=@notes.md` ([Data](data.md#--set)). Most
languages write JSON for you: build an object and serialise it (`json.dumps`, `JSON.stringify`,
`jq -n --arg`), never by pasting strings together.

A JSON number is not Markdown: it is written in its shortest form (`19.90` → `19.9`, `1e3` → `1000`),
and from 10^16 a whole number written with a decimal point or an exponent keeps an exponent (`1e16` →
`1e+16`). Send what you print as a string: `"price": "19.90"`
([details](template-syntax.md#empty-missing-and-false)).

## In headers, footers and footnotes

These hold paragraphs only. A block value there may contain paragraphs and lists (paragraphs take
the header paragraph's style, list items are Word list paragraphs); a table is turned into
paragraphs, one per row with tabs between cells, with the warning above. Pictures work (a logo in a
header: see [Pictures](images.md#pictures-in-headers-and-footers)). A footnote mark (`[^1]`) in a
value placed in a header, a footer, a footnote or a text box is left out, with its note, and the
report warns: Word has no notes there.

```text
warning: footnote of hfn in a header, a footer, a note or a text box, where Word has none: left out (header, block 3: “Inline: {{hfn}}”)
```

More on these places: [Where placeholders work](where-tags-work.md).
