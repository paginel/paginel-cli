# Troubleshooting

Start with these two commands: they show what the template expects and what the fill did.

```sh
paginel-text fields template.docx                            # the placeholders, as the fill sees them
paginel-text fill template.docx data.json out.docx --json    # the full report, every warning
```

- [Messages, one by one](#messages-one-by-one)
- [A placeholder is still there in the result](#a-placeholder-is-still-there-in-the-result)
- [A value is missing or empty](#a-value-is-missing-or-empty)
- [The value has the wrong format](#the-value-has-the-wrong-format)
- [A picture is a grey frame](#a-picture-is-a-grey-frame)
- [The picture has the wrong size](#the-picture-has-the-wrong-size)
- [The PDF does not look like Word's](#the-pdf-does-not-look-like-words)
- [Word says the file is damaged](#word-says-the-file-is-damaged)
- [Installation](#installation)
- [Messages in the wrong language](#messages-in-the-wrong-language)

## Messages, one by one

| Message (English) | Exit | Cause | Fix |
|---|---|---|---|
| `missing values (3): miss, nothing, block_missing` | 0 | the data has no such keys | add them, or check their spelling against `data keys not used` |
| `absent sections, taken as false (1): signature` | 0 (3 with `--strict`) | a `{{#signature}}` key is not in the data | give it, even as `false` or `[]`, if its absence is intended |
| `data keys not used (1): id` | 0 | a key of the data matches no tag | harmless; often a typo next to a missing value |
| `“{{ a b }}” looks like a tag but is not one: left as it is` | 0 (3 with `--strict`) | a space, two dots or nothing between the braces | use letters, digits, `_`, `-` and dots |
| `“{{> other}}”: unsupported tag (partials, delimiter changes): left as it is` | 0 (3) | Mustache partials and delimiter changes are not supported | put the text in a value instead |
| `l is an object or a list: {{l}} expects a text (a list is walked with {{#l}}…{{/l}}); left empty` | 0 | `{{key}}` on a list or an object | use `{{#l}}…{{/l}}`, or `{{l.name}}` |
| `image “images/nope.png” of photo not read (file not found: /home/me/data/images/nope.png): grey “image to provide” frame` | 0 (3) | the file is not at that path, relative to the base folder | see [A picture is a grey frame](#a-picture-is-a-grey-frame) |
| `image title “width 5,5cm” of photo not understood (…): natural size` | 0 | a title word or number not understood | `5.5cm` with a dot; see the [vocabulary](images.md#placement) |
| `table of tbl where it cannot go (within a line, a header, a footer or a note): its text, one line per row` | 0 | a table in an inline value, a header, a footer or a note | put the placeholder alone in a body paragraph, or draw the table in the template |
| `the template is a .dotx: the result is a .docx document (without macros)` | 0 | a Word template or macro file | nothing to do; it is information |
| `“{{x}}” in an endnote: tag not filled in this place (not supported), left as it is` | 0 (3) | a tag in an endnote, a comment, a field code, or a section in a link address | move it to the body, a footnote or a header |
| `footnote of k in a header, a footer, a note or a text box, where Word has none: left out` | 0 | a value with `[^1]` placed in a header, a footer, a note or a text box | put the note text in the value itself |
| `section chapters has no item: its 1 section break(s) are removed with it` | 0 | a block loop over a section break, with an empty list | nothing to do, if no item is intended |
| `--strict: 4 problem(s), nothing written` | 3 | `--strict` and something above | fix the data or the template; the lines above say what |
| `template.docx: error in the tags:` then one line per error | 1 | sections that do not match | see [“error in the tags”](#error-in-the-tags) |
| `bad.json: invalid JSON, line 1, column 9: trailing comma` | 1 | the JSON is not valid | fix it at that place; `jq . bad.json` shows the same |
| `stdin: the data must be a JSON object ({"key": "value", …})` | 1 | the data is a list or a value | wrap it: `{"items": [...]}` |
| `data.json: larger than 50 MiB` | 1 | the data file is too large | split the work, or move pictures out of `data:` addresses into files |
| `list items has 100001 items: 100000 at most` | 1 | a list longer than the limit | split it over several documents |
| `the filled document would exceed 1000000 blocks: check the loops and the data` | 1 | loops multiply too much (often a list nested in itself) | check the data and the nesting |
| `the filled document would exceed 50 million characters: check the loops and the data` | 1 | long values repeated by loops | check the data and the nesting |
| `--base nowhere: folder not found` | 1 | `--base` names a folder that does not exist | give an existing folder |
| `nodir/out.docx: folder nodir does not exist (it is not created)` | 1 | the output's folder does not exist | `mkdir -p nodir` first |
| `out.docx: read-only file, not replaced` | 1 | the output exists and is read-only | write elsewhere, or make it writable |
| `locked/out.docx: cannot write in folder /home/me/locked (permission denied)` | 1 | the output's folder refuses writing | write elsewhere |
| `missing.md: file not found (looked for /home/me/missing.md)` | 1 | a `--set key=@missing.md` file, the data file or the template is not there | check the path, relative to the current folder |
| `template.docx: unreadable Word document: not a valid .docx archive (…)` | 1 | not a Word file, or damaged | open it in Word and save it again as `.docx` |
| `template.docx: unreadable Word document: file refused: word/document.xml: the part exceeds 256 MB once decompressed (a booby-trapped file?)` | 1 | a part far too large once decompressed (a “zip bomb”); or `all the parts of the file exceed 256 MB` | use a normal Word file |
| `section a is nested more than 32 levels deep: simplify the template (…)` | 1 | sections nested too deep | simplify the template |
| `“{{a0.a1.a2.a3.a4.a5.a6.a7.a8.a9.a10.a11.…”: a key has at most 32 segments (a.b.c…) (…)` | 1 | a dotted name of more than 32 parts | shorten the name |
| `sections within lines would repeat more than 500000 times: check the nested loops and the data` | 1 | loops within a line multiply too much | check the data and the nesting |
| `the output would overwrite the template: choose another file` | 2 | OUTPUT is the template (same file, any path) | write elsewhere |
| `--set team.0.name: team is a list in the data; --set cannot change one of its items (give the list in DATA)` | 2 | `--set` into a list | give the list in the JSON |
| `--set body=@-: standard input is already read (by DATA or another @-)` | 2 | `@-` with DATA `-`, or two `@-` | put one of them in a file |
| `--lang de: fr or en expected` | 2 | `--lang` other than `fr` or `en` | `--lang fr` or `--lang en` |
| `unknown option: --nope` | 2 | a typo in an option | `paginel-text fill --help` |
| `output .xlsx: .docx, .pdf or .md expected` | 2 | an output extension `fill` cannot write | use `.docx`, `.pdf` or `.md` |
| `output out: no extension; .docx, .pdf or .md expected (the extension chooses the format)` | 2 | an output without an extension, or `-` | add `.docx`, `.pdf` or `.md` |
| `template .txt: .docx, .dotx, .docm, .dotm or .md expected` | 2 | a template extension `fill` cannot read | convert it first (`paginel-text convert x.txt x.md`) |
| `wrong arguments: TEMPLATE [DATA] OUTPUT` | 2 | too few or too many arguments | check the quoting of values with spaces |
| `no data: give a DATA file (or -) or --set options` | 2 | neither DATA nor `--set` | give one |
| `--set noequals: KEY=VALUE expected` | 2 | `--set` without `=` | `--set key=value` |
| `--set: invalid key “a b” (letters, digits, _ and -, at most 32 segments separated by dots)` | 2 | a key with a space or a forbidden character | rename the key |
| `--pdfa=3x: --pdfa, --pdfa=2a or --pdfa=2b` | 2 | an unknown PDF/A level | one of the three |
| `--strict takes no value` | 2 | `--strict=yes` | `--strict` alone |
| `--schema, --example and --json exclude each other` | 2 | `fields` with two options | one at a time |

## A placeholder is still there in the result

- **The key is not in the data**, or is spelt differently: names are case-sensitive, and `client.name`
  is not `client_name`. The report lists missing keys and unused data keys side by side: a typo shows
  as one of each.
- **`--keep-missing`** was given: missing values leave their tags on purpose.
- **The tag is not understood**: `{{ first name }}` (a space inside a name), `{{client..name}}`. The
  report warns “looks like a tag but is not one”.
- **The placeholder is in a place the fill does not reach**: an endnote, a comment, a field code,
  the document properties. See [Where placeholders work](where-tags-work.md#not-reached).
- **The tag is inside a value**: values are never read for tags, on purpose.

## A value is missing or empty

- A block placeholder whose value is missing, `null` or `""` removes its paragraph from the body; in
  a header or a footer the paragraph stays, empty. An inline one writes nothing.
- A value that is a list or an object in `{{key}}` is written empty, with a warning.
- A section whose key is `"false"` from `--set` shows (a non-empty text is true): use JSON `false`.
- A value from a shell variable that was empty is `""`, which is present: `--strict` does not catch it.
  Check variables in your script.

## The value has the wrong format

- An inline value takes the format of the **first character** of the placeholder. If `{{name}}` is
  half bold in the template, select it all and set its format once.
- Underscores or asterisks turned into italics or bold: the value is Markdown. Use `{{&key}}` for
  plain text, or escape them (`\_`).
- A value written on several lines came out on one line: a single newline is a space in Markdown.
  Use a blank line for a new paragraph, `\` or two spaces at the end of a line for a line break, or
  `--breaks`.
- A block value's paragraphs have an unexpected style: they take the style of the paragraph that
  held the placeholder. Change that paragraph's style in the template.
- A heading of the value has the wrong look: it takes the template's *Heading N* style. Change that
  style in the template.
- `0042` became `42`, `19.90` became `19.9`: numbers are normalised. Send strings.

## “error in the tags”

The message gives the place (`body, block 3`, `row 1, cell 1`, `header`…, blocks counted from 1)
and an excerpt of the paragraph, then says what to do. Usually:

- a section opens in one kind of place and closes in another (body and table cell): move one tag;
- a section tag shares its paragraph with text while its closing tag is in another paragraph: put
  each tag alone in its paragraph, or both in the same paragraph;
- a `{{/key}}` is missing, or has a different name than its `{{#key}}`;
- two sections cross instead of nesting.

Every error is listed at once. See [Loops and conditions](loops-and-conditions.md#anything-else-is-an-error).

## A picture is a grey frame

The grey frame (“image to provide”) means the picture could not be used. The warning says why:

- **file not found**: the path is relative to the **data file's folder** (or the current folder for
  standard input, the folder of a `--set key=@file.md`, or `--base`), not to your current folder.
  The warning names the path that was tried.
- **outside the base folder** or **absolute path**: refused for safety; use `--base` or
  `--allow-any-path` if you trust the data;
- **network address**: never downloaded; download it first;
- **not a PNG, JPEG, GIF, WebP, TIFF or SVG image**, or **SVG**: convert it to PNG;
- **file larger than 20 MiB**: make it smaller.

A `data:` address that is not a base64 PNG, JPEG, GIF, WebP or TIFF image is left out, without a
frame, with the same kind of warning. `--strict` turns all of these into an error (exit code 3).

## The picture has the wrong size

- No title: natural size at 96 dpi, reduced to the text width. A phone photo is large: give it a
  `"width …"`.
- `"width 5,5cm"` is not understood (use a dot: `5.5cm`): the report warns, and the picture keeps its
  natural size. The whole title is ignored when one item in it is not understood.
- In a table cell of the template, `width 50%` is half **the cell**, not half the page.

## The PDF does not look like Word's

Fonts are the usual reason: `paginel-text info template.docx` shows which built-in font replaces
each font (`fonts Calibri → Carlito`). See [Limitations](limitations.md#pdf-output). Compare with the
`.docx` opened in Word; if the `.docx` is right, make the PDF from Word or LibreOffice, or embed the
template's fonts. Even with the same fonts, `paginel-text`'s PDF is close to Word's but not identical:
lists are less indented and table cells are tighter. The `.docx` is what Word shows.

## Word says the file is damaged

That is a bug: please report it, with the smallest template and data that show it (nothing
confidential), the command line, and the output of `paginel-text --version`, to
[issues](https://github.com/paginel/paginel-cli/issues) or hello@paginel.com.

## Installation

- **macOS**: there is no macOS build in 0.3.0; it comes in a later version.
- **Linux: “version `GLIBC_2.35' not found”**: the system is older than Ubuntu 22.04 or Debian 12
  (RHEL 9 and its rebuilds included). Use a newer system or a container (`debian:12-slim`).
- **Linux: “not found” although the file is there**: probably Alpine (musl). Use a glibc-based image.
- **Windows: “Windows protected your PC”** (SmartScreen): click *More info*, then *Run anyway*. Or
  unblock the zip before extracting it: right-click › *Properties* › *Unblock*.
- **Windows PowerShell 5.1: accented keys reported missing** (`date_début` missing, `date_d?but` not
  used) when the JSON comes through a pipe: PowerShell sent it as US-ASCII. Give the file name
  instead, or set `$OutputEncoding = [System.Text.UTF8Encoding]::new($false)` and read the file with
  `Get-Content data.json -Raw -Encoding UTF8` ([Data](data.md#windows-powershell-51)). A data file
  written by `>` or `Out-File` (UTF-16) is read as it is.
- **`command not found`**: the folder of `paginel-text` is not on your `PATH`.

## Messages in the wrong language

Set `--lang en` or `--lang fr`, or the `PAGINEL_LANG` environment variable. Without them, a `LANG`
(or `LC_ALL`, `LC_MESSAGES`) starting with `fr` gives French. On Windows, when none of these
variables is set, the Windows display language decides: French Windows gives French messages.
