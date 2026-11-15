# Changelog

All notable changes to `paginel-text`. Its version number follows the
[Paginel Text app](https://github.com/paginel/paginel-text)'s: both are built from the same engine.

## 0.3.0 — 2026-11-15

First public release.

- **`paginel-text fill`**: fills a Word template (`.docx`, `.dotx`, `.docm`, `.dotm`) or a Markdown
  template (`.md`) with values from JSON (a file or standard input), `--set KEY=VALUE` or
  `--set KEY=@FILE.md`, and writes a `.docx`, a `.pdf` or a `.md`.
  - Tags: `{{key}}`, `{{a.b}}`, `{{.}}`, `{{&key}}` and `{{{key}}}` (plain text), sections
    `{{#key}}…{{/key}}` and inverted sections `{{^key}}…{{/key}}`, comments `{{! … }}`, with
    Mustache's context stack. Names may use any Unicode letter.
  - Values are Markdown: inline formatting in a sentence, in the placeholder's own font; headings,
    lists, quotes, code, tables, pictures, page breaks and footnotes when the placeholder is alone in
    its paragraph, with the template's styles.
  - Pictures from local files (PNG, JPEG, GIF, WebP, TIFF) or `data:` addresses, sized and placed by
    their title (`"width 5cm"`, `"width 50%"`, `"right; width 35%"`, `"behind; page 0 0"`…),
    confined to the data's folder unless `--allow-any-path`; never downloaded.
  - Sections repeat a piece of a paragraph, paragraphs and list items (numbering continues), or table
    rows (keeping the table's style); they nest.
  - Placeholders are found in the body, tables, headers and footers (first page, even pages, every
    section), footnotes, text boxes, content controls, and the text and addresses of hyperlinks, even
    when Word split them across several runs. Tags in endnotes, comments and field codes are
    reported, not filled.
  - Everything the fill does not change is copied byte for byte from the template.
  - `--strict`, `--keep-missing`, `--breaks`, `--json`, `--base`, `--allow-any-path`, `--pdfa`,
    `--lang`. Exit codes 0, 1, 2, 3.
  - Data files in UTF-8 (with or without a byte order mark) or in UTF-16 with a byte order mark, as
    Windows PowerShell 5.1 writes them with `>` and `Out-File`; the same for `--set KEY=@FILE`.
  - Messages that say what to do: an output folder that does not exist (`folder out does not exist
    (it is not created)`), an output without an extension, a read-only output (`read-only file, not
    replaced`), a folder that refuses writing, invalid JSON with its line and column, `1 value
    written` in the singular.
  - An existing output is replaced through a temporary file and keeps its permissions; a failure
    leaves it untouched.
- **`paginel-text fields`**: the placeholders a template expects, as a tree, as JSON, as a JSON
  Schema (`--schema`) or as a data skeleton (`--example`).
- **`paginel-text convert`**: Word, Markdown, text and PDF conversions; a Markdown file's local
  pictures are read relative to its folder.
- Messages in English and French: `--lang`, else `PAGINEL_LANG`, `LC_ALL`, `LC_MESSAGES` or `LANG`;
  on Windows without them, the Windows display language.
- Binaries for Linux x86_64 (glibc 2.35 or later) and Windows x64 (Windows 10 and 11, no Visual C++
  runtime needed). No macOS build in this version: it comes in a later one.
