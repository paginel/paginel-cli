# Command-line reference

```text
paginel-text fill TEMPLATE [DATA] OUTPUT [options]
paginel-text fields TEMPLATE [--schema | --example | --json]
paginel-text convert INPUT OUTPUT [--pdfa[=2a|2b]]
paginel-text info INPUT
paginel-text dump INPUT
paginel-text save ORIGINAL.docx EDITED OUTPUT.docx
paginel-text help [COMMAND]  |  paginel-text COMMAND --help  |  paginel-text --version
```

- Every option accepts both `--option value` and `--option=value`; options may come before, between
  or after the arguments. A flag takes no value (`--strict=yes` is an error).
- An unknown option, a missing argument or a wrong extension is a usage error: exit code 2, a
  message and `see `paginel-text fill --help`` on standard error.
- Paths may be relative to the current folder. `-` as DATA is standard input.
- Every command takes `--lang fr|en` ([Messages and language](#messages-and-language)).

Contents: [`fill`](#fill) · [`fields`](#fields) · [`convert`](#convert) · [`info`](#info) ·
[`dump`](#dump) · [`save`](#save) · [`help`, `--version`](#help---help---version) ·
[Exit codes](#exit-codes) · [The report](#the-report) · [JSON output](#json-output) ·
[Messages and language](#messages-and-language) · [Environment](#environment)

## `fill`

Fills a template with data and writes the result.

| Argument | |
|---|---|
| `TEMPLATE` | a Word template: `.docx`, `.dotx`, `.docm`, `.dotm`; or a Markdown template: `.md`, `.markdown` |
| `DATA` | a JSON file, or `-` for standard input. Optional when `--set` gives the values |
| `OUTPUT` | `.docx`, `.pdf` or `.md` (`.markdown`): the extension chooses the format |

| Option | |
|---|---|
| `--set KEY=VALUE` | a value, as Markdown text. Repeatable. `KEY` may be dotted (`client.name`). Applied after the JSON: it wins |
| `--set KEY=@FILE` | the value is the content of `FILE` (pictures in it are read relative to `FILE`'s folder); `@@` at the start for a real `@`; `@-` for standard input (once, and not when `DATA` is `-` or `/dev/stdin`) |
| `--base DIR` | the folder relative picture paths are read from (default: the folder of the `DATA` file; the current folder for standard input or without `DATA`) |
| `--allow-any-path` | allow absolute picture paths and paths outside the base folder (never web addresses) |
| `--breaks` | in Markdown values, a single newline is a line break (as in GitHub comments) |
| `--keep-missing` | leave `{{key}}` in place when the data has no value (to fill in several passes) |
| `--strict` | a missing value or section key, an unreadable picture, a tag not understood or a tag where the fill does not go (endnote, comment, field code) stops the fill: exit code 3, nothing written. An HTML `<img>` in a value is not a picture to it: it is left out, and `--strict` does not see it ([Pictures](images.md)) |
| `--json` | print the report as one JSON object on standard output ([JSON output](#json-output)) |
| `--pdfa`, `--pdfa=2a`, `--pdfa=2b` | for a `.pdf` output: PDF/A. `--pdfa` alone: 2a when the document allows it, otherwise 2b |
| `--lang fr` / `--lang en` | the language of the messages |

What it does with each kind of template and output:

| Template → output | |
|---|---|
| `.docx` → `.docx` | the template's own package is kept: everything the fill does not change is copied byte for byte (styles, theme, numbering, headers, section settings, comments, fields, custom XML…) |
| `.dotx`, `.dotm`, `.docm` → `.docx` | the same, saved as a document: the content type becomes a document's, macros are **dropped**, and the report warns: `the template is a .dotx: the result is a .docx document (without macros)`. The kind is read from the file's content, not its extension |
| `.md` → `.docx` | a new Word document from the filled Markdown, with Paginel's default styles and the front matter's page settings |
| Word → `.pdf` | the filled `.docx`, laid out by Paginel's engine with its built-in fonts and the fonts the `.docx` embeds ([Limitations](limitations.md#pdf-output)) |
| `.md` → `.pdf` | the filled Markdown laid out directly |
| any → `.md` | the filled document as Markdown; pictures are embedded as `data:` addresses |

- The output may already exist: it is replaced, and keeps its permissions. A `--strict` failure or
  an error leaves an existing output untouched. A read-only output is not replaced
  (`ro.md: read-only file, not replaced`, exit code 1).
- The output can never be the template itself, by any path (`./`, `../`, a symbolic link, a hard
  link): `the output would overwrite the template: choose another file`, exit code 2.
- The output's folder must exist: `fill` does not create it (`nodir/o.md: folder nodir does not
  exist (it is not created)`, exit code 1). Run `mkdir -p out` first.
- The output is written to a temporary file in the same folder, then renamed: an existing output is
  replaced at once, never left half written, and a symbolic link given as OUTPUT is replaced by the
  file, not followed.
- With `--pdfa=2a`, a document holding pictures added from values fails (they have no alternative
  text): exit code 1, `x.pdf: PDF/A not possible: an image has no alternative text`; `--pdfa` alone
  then gives PDF/A-2b. The PDF/A level reached is printed: `x.pdf: PDF/A-2b`.

Usage errors of `fill`, as printed (exit code 2):

```text
unknown option: --nope
output .xlsx: .docx, .pdf or .md expected
output o: no extension; .docx, .pdf or .md expected (the extension chooses the format)
template .txt: .docx, .dotx, .docm, .dotm or .md expected
wrong arguments: TEMPLATE [DATA] OUTPUT          (then the help of fill)
no data: give a DATA file (or -) or --set options
--strict takes no value
--set needs a value
--set noequals: KEY=VALUE expected
--set: invalid key “a b” (letters, digits, _ and -, at most 32 segments separated by dots)
--set body=@: a file name is expected after @ (@@ for a real @)
--set body=@-: standard input is already read (by DATA or another @-)
--set team.0.name: team is a list in the data; --set cannot change one of its items (give the list in DATA)
--pdfa=3x: --pdfa, --pdfa=2a or --pdfa=2b
--lang de: fr or en expected
the output would overwrite the template: choose another file
```

Errors with exit code 1:

```text
--base nowhere: folder not found
bad.json: invalid JSON, line 1, column 9: trailing comma
stdin: the data must be a JSON object ({"key": "value", …})
data.json: larger than 50 MiB
missing.md: file not found (looked for /home/me/missing.md)
nodir/o.md: folder nodir does not exist (it is not created)
ro.md: read-only file, not replaced
locked/o.md: cannot write in folder /home/me/locked (permission denied)
template.docx: unreadable Word document: not a valid .docx archive (…)
template.docx: list items has 100001 items: 100000 at most
template.docx: error in the tags:
{{#a}} is never closed: add {{/a}} in the same container (the body, the same cell, the same header), or in another cell of the same table to repeat rows (body, block 1: “{{#a}}”)
```

## `fields`

Lists the placeholders of a template, without filling it. See [Fields](fields.md) for the outputs.

| Option | Prints |
|---|---|
| *(none)* | a readable tree of the tags |
| `--json` | the tree as JSON: `[{name, kind, placement, where, children}]` |
| `--schema` | a JSON Schema (draft 2020-12) of the data the template expects |
| `--example` | a data skeleton to fill in |

The options exclude each other. A template with an error is reported as by `fill`: exit code 1.

## `convert`

Converts a document with the same engine as the Paginel app. See [Converting](convert.md).

| Input | Output |
|---|---|
| `.docx`, `.dotx`, `.docm`, `.dotm`, `.md`, `.markdown`, `.txt`, `.pdf` | `.docx`, `.pdf`, `.md`, `.markdown`, `.txt` |

`--pdfa` as for `fill`. The local pictures of a Markdown input are read relative to its folder.
Unknown extensions: `unsupported input format: .zip`, `unsupported output format: .zip`; no
extension: `x: no extension; the output format comes from the extension (.docx, .pdf, .md, .txt)`
(exit 2). As for `fill`, the output's folder must exist.

## `info`

Prints what was understood of a document, for checking how a template is read:

```text
$ paginel-text info letter.docx
page       A4 portrait
blocks     20 paragraphs (1 headings, 6 list items), 0 tables
text       795 characters
objects    0 images (0 files), 0 footnote references (0 notes), 1 runs with a link
header     Bluefin Studio / www.example.org
footer     Bluefin Studio · 1 Example Street, 75001 Paris · hello@example.org
properties title Customer letter; author Paginel examples; language en-US
bookmarks  0
pages      1 (Paginel's layout)
fonts      Calibri → Carlito
```

The `fonts` line says which built-in font replaces each font of the document in a PDF.

## `dump`

One line per block: index, flags, style, text, and the pictures with their placement. For debugging
how a document was read.

## `save`

`paginel-text save ORIGINAL.docx EDITED OUTPUT.docx` writes the changes of `EDITED` (a `.md` or a
`.docx`) into the package of `ORIGINAL.docx`, keeping what did not change (comments, fields, styles,
theme…). The report goes to standard error:

```text
blocks kept 19, patched 1, rewritten 0, unrecognized 0; parts rewritten: word/document.xml
```

See [Converting](convert.md#editing-a-word-file-as-markdown).

## `help`, `--help`, `--version`

- `paginel-text --help`, `-h` or `help`: the commands (standard output, exit code 0).
- `paginel-text help fill`, `paginel-text fill --help`: the options of one command.
- `--lang` works with all of them: `paginel-text --help --lang fr`, `paginel-text help --lang fr fill`.
- `paginel-text --version`, `-V` or `version`: `paginel-text 0.3.0`.
- An unknown command prints `unknown command: frobnicate`, then the general help, exit code 2.

## Exit codes

| Code | Means |
|---|---|
| 0 | done (even with warnings) |
| 1 | a file could not be read or is not valid (template, data, `@FILE`, picture folder), the template has an error, a limit was reached, or the output could not be written |
| 2 | wrong usage: unknown option, missing or extra argument, wrong extension, invalid `--set`, `--lang` other than `fr` or `en`, output that would overwrite the template |
| 3 | `--strict`, and a value, a section key or a picture was missing, or a tag was not understood or not filled where it is: nothing was written |

A program that crashes would exit otherwise (101 for an internal error): please report it. Writing to
a closed pipe (`paginel-text fields big.docx | head -1`) ends quietly.

## The report

`fill` prints a short report on **standard error**: the number of placeholders filled, the missing
keys (with their path, `items[2].price`), the absent sections, the keys of the data no placeholder
used, the warnings, and, for a `.docx` output, what happened to the template's package. Example and
line-by-line meaning: [Data › The report](data.md#the-report). Standard output stays empty, unless
`--json`.

The first 20 missing keys and the first 20 warnings are shown; the rest are counted:
`missing values (25): m0, m1, …, m19 … and 5 more`, `… and 5 more warnings (--json for all)`.

## JSON output

With `--json`, `fill` prints **one JSON object** on standard output, whatever the outcome (an
invalid `--lang` included), and only the error message on standard error when it fails.

**Success** (exit code 0), from [examples/01-letter](../examples/01-letter/) with one value given
(`paginel-text fill template.docx out/one.docx --set city=Lyon --json`):

```json
{
  "exit": 0,
  "filled": 1,
  "missing": [
    {
      "key": "date",
      "section": false,
      "where": {
        "excerpt": "{{city}}, {{date}}",
        "path": [
          {
            "block": 0
          }
        ],
        "story": "body"
      }
    },
    {
      "key": "signature",
      "section": true,
      "where": {
        "excerpt": "{{#signature}}",
        "path": [
          {
            "block": 11
          }
        ],
        "story": "body"
      }
    }
  ],
  "ok": true,
  "output": "out/one.docx",
  "template": "template.docx",
  "unused": [],
  "warnings": [],
  "word": {
    "fallback": null,
    "kept": 0,
    "parts": [
      "word/document.xml",
      "word/header1.xml",
      "word/footer1.xml"
    ],
    "patched": 12,
    "rewritten": 0,
    "skipped": 0,
    "warnings": []
  },
  "written": true
}
```

(Shortened: the real `missing` list has all 17 missing keys.)

| Key | |
|---|---|
| `ok` | `true` when the output was written |
| `exit` | the exit code |
| `written` | whether the output file was written |
| `template`, `output` | the paths as given |
| `filled` | the number of values written (every loop copy counted) |
| `missing` | `[{key, section, where}]`: `section` is `true` for a loop or condition key |
| `unused` | data keys no tag used: `"notes"`, `"items[].sku"` |
| `warnings` | `[{code, message, strict, …}]`; `strict: true` when `--strict` refuses it |
| `word` | for a Word template written as `.docx`: blocks `kept`, `patched`, `rewritten`, `skipped`, the `parts` rewritten, `fallback` and its own `warnings`; for a PDF made from a Word template: `{"warnings": […]}` only; `null` for a `.md` output or a Markdown template |

`where` places a tag: `story` (`body`, `header`, `footer`, `first-header`, `first-footer`,
`even-header`, `even-footer`, `footnote`, with `section` for the headers of another section and
`footnote` for the note's id), `path` (`{"block": i}` and `{"row": r, "cell": c}` steps, counting from
0) and `excerpt` (the start of the paragraph).

Warning `code`s, with their extra keys:

| Code | Extra keys | Strict |
|---|---|---|
| `unknown_tag` | `text` | yes |
| `unsupported_tag` | `text` | yes |
| `not_a_value` (an object or a list in `{{key}}`) | `key` | no |
| `image_not_read` | `key`, `source`, `problem` (`not_found` and `not_a_file` with `path`, `outside_base` with `base`, `absolute_path`, `remote`, `too_large`, `not_an_image`, `invalid_data_uri`, `unreadable`, `document_image`) | yes |
| `svg_image` | `key`, `source` | yes |
| `image_title` (title not understood) | `key`, `title` | no |
| `table_flattened` | `key` | no |
| `template_converted` (`.dotx`, `.dotm`, `.docm`) | `from` | no |
| `tag_not_supported_here` (a tag in an endnote, a comment, a field code, or a section in a link address) | `text`, `place` (`endnote`, `comment`, `field-code`, `link-address`) | yes |
| `footnote_dropped` (a value's footnote in a header, a footer, a note or a text box) | `key` | no |
| `section_breaks_removed` (a loop with no item held section breaks) | `key`, `count` | no |

Each warning also has `where` when it has a place in the template. New codes may be added: treat an
unknown code as a warning, and rely on `strict`.

**Failure**: `ok` is `false`, `exit` is 1, 2 or 3, and `error` says why:

```json
{
  "error": {
    "code": "template",
    "errors": [
      {
        "code": "unclosed_section",
        "message": "{{#a}} is never closed: add {{/a}} in the same container (the body, the same cell, the same header), or in another cell of the same table to repeat rows (body, block 1: “{{#a}}”)",
        "where": {
          "excerpt": "{{#a}}",
          "path": [
            {
              "block": 0
            }
          ],
          "story": "body"
        }
      }
    ],
    "message": "{{#a}} is never closed: add {{/a}} in the same container (the body, the same cell, the same header), or in another cell of the same table to repeat rows (body, block 1: “{{#a}}”)"
  },
  "exit": 1,
  "ok": false,
  "template": "e_unclosed.docx"
}
```

```json
{
  "error": {
    "code": "usage",
    "message": "unknown option: --nope\nsee `paginel-text fill --help`"
  },
  "exit": 2,
  "ok": false
}
```

```json
{
  "error": {
    "code": "file",
    "message": "stdin: invalid JSON, line 2, column 0: EOF while parsing an object"
  },
  "exit": 1,
  "ok": false
}
```

A `--strict` failure (exit code 3) keeps the whole report, with `"ok": false`, `"written": false`
and `"error": {"code": "strict", "message": "--strict: 2 problem(s), nothing written"}`.

| `error.code` | |
|---|---|
| `usage` | exit code 2 |
| `file` | a file could not be read, written or parsed (exit code 1) |
| `template` | errors in the tags, all of them in `errors` (exit code 1); each has a `code`: `unclosed_section`, `unexpected_close`, `mismatched_close`, `section_spans_paragraphs`, `row_section_in_one_cell`, `row_sections_overlap`, `sections_too_deep`, `key_too_long` |
| `docx` | the Word template could not be read (exit code 1) |
| `too_large` | a limit was reached: a list of more than 100 000 items, more than 1 000 000 blocks, 500 000 repetitions within lines or 50 million characters (exit code 1) |
| `strict` | `--strict` refused the fill (exit code 3); the rest of the report is there too |

`fields --json` prints the tree only; a failure there is reported on standard error.

## Messages and language

Messages are in English or French. The language is `--lang` if given; otherwise the first of the
`PAGINEL_LANG`, `LC_ALL`, `LC_MESSAGES` and `LANG` environment variables that is set: French if it
starts with `fr`, English for anything else. When none is set, Windows uses its display language
(French Windows: French messages); other systems use English. Every message has both languages,
including those about the Word package and PDF/A; a detail quoted from below (an archive or system
error) may stay in English.

```text
$ LANG=fr_FR.UTF-8 paginel-text fill t.md o.md --set a=1
t.md → o.md : 1 valeur écrite
valeurs manquantes (4) : b.c, c, d, e
```

`--lang` other than `fr` or `en` is a usage error (exit code 2).

## Environment

| Variable | |
|---|---|
| `PAGINEL_LANG` | `fr` or `en`: the language of the messages |
| `LC_ALL`, `LC_MESSAGES`, `LANG` | used for the language when `PAGINEL_LANG` is not set; without any of them, the Windows display language on Windows, English elsewhere |

`paginel-text` reads no proxy variable and no configuration file, writes nothing but the output you
name (no cache, no log), and has no networking code: it never opens a network connection itself, and
web pictures are never downloaded. A path that points to a network share is opened like any file, so
your operating system fetches it from that share ([Privacy](../README.md#privacy-works-offline)).
