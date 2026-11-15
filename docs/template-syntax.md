# Template syntax

A template is an ordinary Word document (`.docx`, `.dotx`, `.docm`, `.dotm`) or a Markdown file
(`.md`, `.markdown`) in which you type **tags** between double braces. `paginel-text fill` replaces
them with values from your data. The syntax is a subset of [Mustache](https://mustache.github.io/);
the difference is that **values are Markdown**.

- [The tags](#the-tags)
- [Names](#names)
- [How a name is looked up](#how-a-name-is-looked-up)
- [Inline or block: where the placeholder is decides](#inline-or-block-where-the-placeholder-is-decides)
- [Typing placeholders in Word](#typing-placeholders-in-word)
- [Empty, missing and false](#empty-missing-and-false)
- [Missing values](#missing-values)
- [What is not supported](#what-is-not-supported)

Every example on this page was run with `paginel-text`, and its result read back from the `.docx`.

## The tags

| Tag | Meaning | Template → result |
|---|---|---|
| `{{key}}` | the value of `key`, read as Markdown | `Dear {{name}},` with `"name": "**Ada**"` → Dear **Ada**, |
| `{{ key }}` | the same: spaces inside the braces are ignored | `[{{ name }}]` → [Ada] |
| `{{a.b.c}}` | a value inside objects | `{{client.address.city}}` with `{"client": {"address": {"city": "Lyon"}}}` → Lyon |
| `{{.}}` | the current item, inside a section over a list of plain values | `{{#tags}}{{.}} {{/tags}}` with `["design", "print"]` → design print |
| `{{&key}}` or `{{{key}}}` | the value as **plain text**: no Markdown, every newline a line break | `{{&file}}` with `"__init__.py"` → \_\_init\_\_.py |
| `{{#key}}` … `{{/key}}` | a **section**: repeated for each item of a list; shown once if `key` is true, a text, a number or an object; removed if `key` is empty | `{{#items}}…{{/items}}` |
| `{{^key}}` … `{{/key}}` | an **inverted section**: shown only if `key` is empty or missing | `{{^items}}Nothing yet.{{/items}}` |
| `{{! text }}` | a comment, removed from the result | `A{{! check with legal }}B` → AB |

Sections (loops and conditions) have their own page: [Loops and conditions](loops-and-conditions.md).

## Names

- A name is one or more **segments** separated by dots. A segment is made of letters, digits, `_`
  and `-`. Letters may be any Unicode letter: `{{date_début}}`, `{{prénom}}`, `{{名前}}`,
  `{{key-with-dash}}` all work.
- `{{.}}` alone means “the current item”.
- Names are case-sensitive: `{{Name}}` and `{{name}}` are two different keys.
- A name with a space, two dots in a row or nothing in it (`{{first name}}`, `{{a..b}}`, `{{}}`) is
  not a tag: see [What is not supported](#what-is-not-supported).
- An accented letter typed as a letter plus a combining accent (some macOS tools write `é` that way)
  is compared after Unicode normalisation (NFC), so it matches the same key typed in one piece, in
  the template and in the data. If the data holds both spellings of one key, only one of the two
  values is kept, without a warning ([Limitations](limitations.md#template-syntax)).
- A name has at most 32 segments, and sections nest at most 32 deep; beyond that the template is
  refused with an error (exit code 1, see
  [Anything else is an error](loops-and-conditions.md#anything-else-is-an-error)).

## How a name is looked up

Like Mustache, `paginel-text` looks a name up in a **stack of contexts**: inside a section, the
current item comes first, then the item of the section around it, and so on, and the root of the
data last.

```json
{
  "city": "Lyon",
  "meeting": { "city": "online", "date": "26 November" }
}
```

| Template | Result |
|---|---|
| `{{city}}` | Lyon |
| `{{#meeting}}{{date}}, {{city}}{{/meeting}}` | 26 November, online |
| `{{meeting.city}}` | online |

For a dotted name, the first segment is looked up through the stack, the rest inside what was
found. When the current item has no such key, the lookup goes on outwards: with
`{"city": "Lyon", "people": [{"name": "Ann", "city": "Paris"}, {"name": "Bob"}]}`,
`{{#people}}{{name}}@{{city}} {{/people}}` gives *Ann@Paris Bob@Lyon*.

## Inline or block: where the placeholder is decides

The same value lands differently depending on what shares the placeholder's paragraph.

### Inline: the placeholder shares its paragraph with other text

```text
Template paragraph:   Your order {{order}} ships on {{date}}.
Data:                 "order": "**A-1042**", "date": "*Friday 13 November*"
Result:               Your order A-1042 ships on Friday 13 November.
                                 ‾‾‾‾‾‾ bold        ‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾ italic
```

- The value is read as **inline Markdown**: bold, italics, strikethrough, code, links, footnotes,
  pictures, inline HTML ([the list](markdown-values.md#inline-formatting)).
- **Block syntax stays text**: a value `2024. A good year`, `- not a list` or `# not a title` is
  written as typed. A value made of several paragraphs is written in the line, its paragraphs
  separated by line breaks. A table is flattened into its text (cells separated by tabs, rows by line
  breaks), with a warning.
- The value takes the **character format of the placeholder** (font, size, colour, highlight… of the
  run that holds the `{{`), with its own Markdown formatting on top: in a red 14 pt sentence, the
  value is red 14 pt; `*x*` adds italics; `<span style="color:#00AA00">` replaces the colour.
  Character properties Word has and Markdown does not (theme fonts, character spacing, scale,
  kerning, language) are kept on every run of the value.
- If the placeholder sits inside a hyperlink of the template, the value is part of that link.

### Block: the placeholder is alone in its paragraph

Spaces and tabs around it do not count.

```text
Template:   ┌──────────────────────────────────────────┐
            │ {{details}}          (Body Text, justified,│
            │                       Georgia 11 pt)       │
            └──────────────────────────────────────────┘
```

The value is read as **full Markdown**, and one of two things happens.

**1. The value is a single plain paragraph** (no heading, list, quote, code block, table): it goes
into the placeholder's paragraph, which keeps everything it had: its style, alignment, spacing,
numbering, borders.

```text
Template:   {{title}}            in a centred paragraph with the "Title" style
Data:       "title": "Annual report 2026"
Result:     Annual report 2026   still a centred "Title" paragraph
```

A value made of one picture is a single plain paragraph too: the picture goes into the placeholder's
paragraph and follows its alignment (centre that paragraph in Word to centre the picture).

**2. Anything else**: the paragraph is **replaced by the value's blocks**.

```text
Data:    "details": "## What happens next\n\n1. We pack your lamp.\n2. The carrier picks it up.\n\nGood to know:\n\n- it comes with a bulb."
Result:  What happens next                  ← the template's "Heading 2"
         1. We pack your lamp.              ← a Word numbered list
         2. The carrier picks it up.
         Good to know:                      ← Body Text, justified, Georgia 11 pt
         • it comes with a bulb.            ← a Word bullet list, justified, Georgia 11 pt
```

- **plain paragraphs** take the placeholder paragraph's style, alignment, spacing, indentation and
  keep options, and the placeholder's character format under their own Markdown formatting;
- **list items** take its alignment, spacing and character format; their indentation comes from the
  list. From the second item on, the character format is the visible one only (bold, italic, colour,
  size, font name): theme fonts, character spacing, scale, kerning and language stay on the first
  item ([Limitations](limitations.md#values));
- **headings, quotes and code blocks** use the template's own styles for them (*Heading 1*…
  *Heading 6*, *Quote*, a code style), found by their built-in identity whatever the template's
  language (*Titre 1* in a French Word);
- **tables** and **pictures** are added as Word tables and pictures ([Tables](tables.md),
  [Pictures](images.md)).

The placeholder paragraph's bookmarks and comments stay on the first block of the value, and a
value placed in a text box or a content control stays inside it. In a block content control, a
value of several plain paragraphs gives one control per paragraph, all with the control's tag.

Details and every Markdown feature: [Markdown values](markdown-values.md).

## Typing placeholders in Word

- Type them as normal text. Word often cuts what you type into several pieces internally (spelling
  marks, revision marks, language changes): `paginel-text` reads the paragraph's text, so a
  placeholder is found however Word stored it.
  [examples/01-letter](../examples/01-letter/) has one cut into three pieces on purpose.
- If a placeholder has two formats (half bold, half not), the format of its **first character** (the
  `{` that opens it) is the one the value takes. Select the whole placeholder and format it at once.
- Word's AutoCorrect does not change braces. It can change quotes or dashes **around** a
  placeholder: that is text, it stays as it is.
- Run `paginel-text fields template.docx` to check that every placeholder was understood
  ([Fields](fields.md)).

## Empty, missing and false

These values count as **empty** (*falsy*): a missing key, `null`, `false`, `""` (empty string), `[]`
(empty list), `{}` (empty object). Everything else is **true**, including `0`, `"0"` and `"false"`
(a non-empty string).

| Value in the JSON | `{{key}}` writes | `{{#key}}…{{/key}}` shows | `{{^key}}…{{/key}}` shows |
|---|---|---|---|
| `"text"` | text (Markdown) | once | no |
| `""` | nothing | no | yes |
| `42`, `0`, `3.5` | `42`, `0`, `3.5` | once | no |
| `true` / `false` | `true` / `false` | once / no | no / yes |
| `null` | nothing | no | yes |
| *missing* | nothing, reported as missing | no | yes |
| `[]`, `{}` | nothing, with a warning | no | yes |
| `[…]` with items | nothing, with a warning | once per item | no |
| `{…}` with keys | nothing, with a warning | once, inside the object | no |

The warning for a list or an object in `{{key}}` reads:

```text
warning: l is an object or a list: {{l}} expects a text (a list is walked with {{#l}}…{{/l}}); left empty (body, block 11: “K: [{{el}}|{{#el}}Y{{/el}}] [{{eo}}|{{#e…”)
```

**Numbers** are written in their shortest form. A whole number written with a decimal point or an
exponent loses them below 10^16 (`1.0` → `1`, `1e3` → `1000`, `2e15` → `2000000000000000`) and keeps
an exponent from 10^16 (`1e16` → `1e+16`); written with digits only, it is printed in full
(`123456789012345678`), up to 64-bit integers. Other numbers take as few digits as needed (`1.50` →
`1.5`, `19.90` → `19.9`). The way the number was written in the JSON is not kept.
So send anything you print as a **string**: `"price": "1,200.50 EUR"`, `"vat": "20%"`,
`"paid": "Yes"`. `paginel-text` does not format numbers or dates, and does not compute (see
[FAQ](faq.md)).

## Missing values

| | Without option | `--keep-missing` | `--strict` |
|---|---|---|---|
| inline `{{key}}` | replaced by nothing | the tag stays | exit code 3, nothing written |
| block `{{key}}` alone in its paragraph | the paragraph is removed | the tag stays | exit code 3, nothing written |
| `{{#key}}` absent | the section is removed | the tags stay | exit code 3, nothing written |

- `null` and `""` are **present** (empty), not missing: `--strict` accepts them, a block placeholder
  with such a value removes its paragraph, and `{{^key}}` shows.
- A block placeholder's paragraph is kept, empty, instead of removed when it also anchors a text box
  or a drawing, or holds a bookmark or a comment.
- A paragraph that holds only sections which all come out empty (`{{#draft}}DRAFT{{/draft}}` with
  `"draft": false`) is removed, so no blank line is left.
- In a header or a footer, such paragraphs (a block placeholder with no value, sections that all
  come out empty) are kept, empty.
- `--keep-missing` and `--strict` together: missing values still fail; absent sections stay as tags
  and do not fail.
- The report printed after each fill lists the missing keys with their path in the data
  (`items[2].price`: the third item, counting from 0), the absent sections, and the data keys no
  tag used:

```text
template.docx → out.docx: 2 values written
missing values (1): amount
data keys not used (1): id
Word: blocks kept 0, patched 3, rewritten 0, unrecognized 0; parts rewritten: word/document.xml
```

## What is not supported

- Changing the delimiters (`{{=<% %>=}}`), partials (`{{> other}}`) and lambdas: left as text, with a
  warning:

  ```text
  warning: “{{> other}}”: unsupported tag (partials, delimiter changes): left as it is (body, block 7: “G: [{{=<% %>=}}] [{{> other}}] [{{ a b }…”)
  ```

- Something that looks like a tag but is not one (`{{ a b }}`, `{{}}`, `{{#}}`) is left as text, with
  a warning:

  ```text
  warning: “{{ a b }}” looks like a tag but is not one: left as it is (body, block 7: “G: [{{=<% %>=}}] [{{> other}}] [{{ a b }…”)
  ```

  With `--strict`, both are errors (exit code 3).
- **Values are never read for tags**: a value `"{{name}}"` is written as `{{name}}`, literally. Data
  cannot inject placeholders.
- To write a literal `{{` in the result, put it in a value: `{{&braces}}` with `"braces": "{{"`.
- A tag cannot span two paragraphs, and a tag inside a picture's path (`![]({{x}})` in a Markdown
  template) is not replaced: put the whole picture in the value instead.
