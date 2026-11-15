# Data

`paginel-text fill` takes its values from a JSON file, from standard input, from the command line,
or from a JSON source and the command line together.

```sh
paginel-text fill template.docx data.json out.docx                           # a JSON file
some-program | paginel-text fill template.docx - out.docx                    # JSON on standard input
paginel-text fill template.docx out.docx --set name=Ada --set body=@body.md  # no JSON at all
paginel-text fill template.docx data.json out.docx --set date="12 May"       # JSON, and one more value
```

- [JSON](#json)
- [`--set`](#--set)
- [Standard input](#standard-input)
- [Picture paths and the base folder](#picture-paths-and-the-base-folder)
- [The report](#the-report)
- [From a program](#from-a-program): Python, Node.js, the shell, CI
- [Exit codes](#exit-codes)

## JSON

The data is **one JSON object**. Keys are placeholder names; values are strings (Markdown), numbers,
booleans, objects (for dotted names and sections) and lists (for loops):

```json
{
  "client": { "name": "Example Retail Ltd", "city": "Manchester" },
  "date": "11 November 2026",
  "items": [
    { "name": "Workshop", "price": "900.00" },
    { "name": "Logo design", "price": "2,400.00" }
  ],
  "paid": false,
  "notes": "Payment within **30 days**."
}
```

How each JSON type is used:

| JSON | In `{{key}}` | In `{{#key}}…{{/key}}` |
|---|---|---|
| string | Markdown (`{{&key}}`: plain text) | shown once if not `""` |
| number | its shortest form: `3`, `1000`, `3.5`, `19.9` (from `19.90`) | shown once, `0` included |
| `true`, `false` | `true`, `false` | shown once / not shown |
| `null` | nothing (present, not missing) | not shown |
| object | nothing, with a warning | shown once, the object becomes the context |
| list | nothing, with a warning | shown once per item |

- **Send strings for anything you print.** Numbers are normalised (`19.90` → `19.9`, `1e3` → `1000`),
  so amounts, codes with leading zeros and formatted dates belong in strings: `"1,200.50 EUR"`,
  `"007"`, `"Yes"`. A whole number written with a decimal point or an exponent prints without `.0`
  below 10^16 (`2e15` → `2000000000000000`) and with an exponent from 10^16 (`1e16` → `1e+16`).
- The file is UTF-8, with or without a byte order mark, or UTF-16 with a byte order mark (what `>`
  and `Out-File` write in Windows PowerShell 5.1). UTF-16 without a byte order mark and 8-bit
  encodings such as Latin-1 are refused as invalid JSON. The file may be up to 50 MiB, and nest up
  to 127 levels.
- Errors are reported with their place, exit code 1, nothing written:

  ```text
  bad.json: invalid JSON, line 1, column 9: trailing comma
  stdin: the data must be a JSON object ({"key": "value", …})
  ```

- Start from the template: `paginel-text fields template.docx --example > data.json` writes a
  skeleton with every key the template uses, and `--schema` a JSON Schema to validate your data with
  ([Fields](fields.md)).
- Keys the template does not use are allowed: the report lists them as “data keys not used”, which
  catches typos.
- Two keys that differ only in their Unicode form (`é` as one letter, or as `e` and a combining
  accent) are the same key: one value is kept, the other dropped without a warning.

## `--set`

`--set KEY=VALUE` gives one value, as Markdown text. It can be repeated.

```sh
--set title="Quarterly review"
--set client.name="Example Retail Ltd"       # a dotted key sets a value inside an object
--set body=@report.md                        # the value is the content of report.md
--set handle=@@paginel                       # "@@" at the start: a value that starts with a real "@"
```

Rules, each one checked with the binary:

- **`--set` wins over the JSON**: the JSON (file or standard input) is read first, then each `--set`
  is applied. With `{"a": "json"}` and `--set a=cli`, `{{a}}` is *cli*.
- A dotted key goes **into** the existing object: with `{"b": {"c": "json", "keep": "k"}}`,
  `--set b.c=new` changes `b.c` and keeps `b.keep`.
- The same key twice: the last one wins (`--set a=1 --set a=2` → *2*).
- A `--set` value is **always a string**. `--set paid=false` is the text “false”, which is not empty:
  `{{#paid}}` shows. Lists, booleans and numbers come from the JSON.
- A `--set` key cannot reach into a list: `--set team.0.name=Zed` is refused (exit code 2, `--set
  team.0.name: team is a list in the data; --set cannot change one of its items (give the list in
  DATA)`); change lists in the JSON. `--set team=x` replaces the whole list with the text.
- `@FILE` reads the value from a file (UTF-8, a byte order mark is ignored; a UTF-16 file with a
  byte order mark, as Notepad or PowerShell may write it, is read too; at most 50 MiB). Pictures in
  it are read relative to **that file's folder**, so a report and its `images/` folder can live
  together.
- `@-` reads the value from standard input; it is refused when the data argument is `-` (or
  `/dev/stdin`) too, or for a second `@-` (standard input can be read once). `--set body=@` (no file
  name) is a usage error.
- Both `--set key=value` and `--set=key=value` work. `=` inside the value is fine
  (`--set formula=a=b`). Quote the value for your shell when it has spaces or special characters.
- Errors (exit code 2):

  ```text
  --set noequals: KEY=VALUE expected
  --set: invalid key “a b” (letters, digits, _ and -, at most 32 segments separated by dots)
  --set body=@: a file name is expected after @ (@@ for a real @)
  ```

  An `@FILE` that cannot be read is exit code 1: `missing.md: file not found (looked for
  /home/me/missing.md)`.

## Standard input

`-` as the data argument reads the JSON from standard input. Relative picture paths are then read
from the current folder (or `--base DIR`).

```sh
jq '.customers[0]' customers.json | paginel-text fill letter.docx - out/letter.docx
```

The same holds when the data argument is a pipe or a process substitution
(`paginel-text fill letter.docx <(jq '.customers[0]' customers.json) out.docx`): pictures are read
from the current folder.

### Windows PowerShell 5.1

In Windows PowerShell 5.1, the PowerShell built into Windows, a pipe into a program is encoded with
`$OutputEncoding`, which is US-ASCII by default: every accented letter becomes `?`, silently. And
`Get-Content` reads a UTF-8 file without a byte order mark in the system's code page unless you add
`-Encoding UTF8`. Even with the file read as UTF-8, keys such as `date_début` are then missing, as
with [examples/05-markdown-template](../examples/05-markdown-template/):

```text
PS> Get-Content data.json -Raw -Encoding UTF8 | paginel-text fill template.md - out\pipe.docx
template.md → out\pipe.docx: 13 values written
missing values (9): date_début, rédacteur, participants[0].rôle, participants[1].rôle, participants[2].rôle, décisions, actions[0].tâche, actions[1].tâche, actions[2].tâche
absent sections, taken as false (1): prochaine_réunion
data keys not used (6): actions[].t?che, d?cisions, date_d?but, participants[].r?le, prochaine_r?union, r?dacteur
```

The simplest is to give the file name instead of a pipe:
`paginel-text fill template.md data.json out\x.docx`. To pipe, send UTF-8 and read the file as
UTF-8; the result is then the same as with the file name:

```powershell
$OutputEncoding = [System.Text.UTF8Encoding]::new($false)
Get-Content data.json -Raw -Encoding UTF8 | paginel-text fill template.md - out\x.docx
```

A file written by `>` or `Out-File` in Windows PowerShell 5.1 is UTF-16 with a byte order mark: it is
read as it is. In `cmd.exe`, `type data.json | paginel-text fill template.md - out\x.docx` works.

## Picture paths and the base folder

Relative paths in Markdown values are read from the **base folder**: the folder of the JSON file, the
current folder for standard input or without JSON, the folder of the file for `--set key=@file.md`,
or `--base DIR`. Absolute paths and paths outside the base folder are refused unless
`--allow-any-path`; web addresses are never downloaded. Details:
[Pictures](images.md#where-pictures-are-read-from).

## The report

After each fill, `paginel-text` prints on **standard error** what it did. Here,
[examples/01-letter](../examples/01-letter/) with `subject` and `signature` removed from the data,
an `id` added, and a picture that is not there:

```text
template.docx → out/letter.docx: 20 values written
missing values (1): subject
absent sections, taken as false (1): signature
data keys not used (1): id
warning: image “images/lamp.png” of details not read (file not found: /home/me/01-letter/./images/lamp.png): grey “image to provide” frame (body, block 9: “{{details}}”)
Word: blocks kept 0, patched 17, rewritten 6, unrecognized 0; parts rewritten: [Content_Types].xml, word/document.xml, word/_rels/document.xml.rels, word/styles.xml, word/numbering.xml, word/header1.xml, word/footer1.xml, word/media/text1.png
```

- *values written*: each placeholder filled, every loop copy counted;
- *missing values* and *absent sections*: keys the template asks for and the data does not have,
  with their path (`items[2].price` is the third item, counting from 0);
- *data keys not used*: keys of the data no placeholder used (`items[].sku` for a key of list items);
- *warning*: pictures, picture titles, tags not understood, tables flattened, a `.dotx` saved as
  `.docx`…; the first 20 are shown, all of them with `--json`;
- *Word*: what happened to the template's package: blocks kept byte for byte, patched, rewritten.
  Shown in full for a `.docx` output; for a PDF made from a Word template, only its warnings; nothing
  for a `.md` output.

With `--json`, the same report is printed as one JSON object on **standard output**, for programs:
[the reference](cli-reference.md#json-output). Standard output is empty without `--json`.

## From a program

`paginel-text` reads JSON on standard input, prints JSON with `--json`, and returns an exit code:
any language can call it. Build the data as an object and let the language serialise it.

### Python

```python
import json
import subprocess

data = {
    "client": {"name": "Example Retail Ltd"},
    "items": [{"name": "Workshop", "price": "900.00"}],
    "notes": "Payment within **30 days**.",
}
result = subprocess.run(
    ["paginel-text", "fill", "template.docx", "-", "out/invoice.docx", "--strict", "--json"],
    input=json.dumps(data), capture_output=True, text=True,
)
report = json.loads(result.stdout) if result.stdout else {"ok": False, "error": {"message": result.stderr}}
if not report["ok"]:
    raise RuntimeError(f"exit {result.returncode}: {report.get('error', {}).get('message') or result.stderr}")
print(report["filled"], "values written, unused keys:", report["unused"])
```

### Node.js

```js
import { spawnSync } from "node:child_process";

const data = {
  client: { name: "Example Retail Ltd" },
  items: [{ name: "Workshop", price: "900.00" }],
  notes: "Payment within **30 days**.",
};
const result = spawnSync(
  "paginel-text",
  ["fill", "template.docx", "-", "out/invoice.docx", "--strict", "--json"],
  { input: JSON.stringify(data), encoding: "utf8" },
);
const report = result.stdout ? JSON.parse(result.stdout) : { ok: false, error: { message: result.stderr } };
if (!report.ok) throw new Error(`exit ${result.status}: ${report.error?.message ?? result.stderr}`);
console.log(`${report.output}: ${report.filled} values`);
```

Both were run as written against a small invoice template (`{{client.name}}`, a table row
`{{#items}}{{name}} | {{price}}{{/items}}`, `{{notes}}`). With `--strict`, every key the template
uses must be in the data, `items` included: give `[]` for no items.

### Shell

```sh
# Values from variables, no JSON file
paginel-text fill letter.docx "out/$CLIENT_ID.docx" \
  --set client.name="$CLIENT_NAME" --set date="$(date +'%d %B %Y')"

# jq builds the JSON from shell variables (quoting done right)
jq -n --arg name "Example Retail Ltd" --arg city "Manchester" '{client: {name: $name, city: $city}}' \
  | paginel-text fill letter.docx - out/letter.docx
```

A value from a shell variable is Markdown: a name like `_Example_` or `*Ltd*` turns into italics.
Use `{{&key}}` in the template for such values.

### In continuous integration

`--strict` makes a missing value, a missing section key, an unreadable picture, a tag not understood
or a tag where the fill does not go fail the job (exit code 3), so a template and its data cannot
drift apart unnoticed. See
[the GitHub Actions recipe](recipes.md#in-github-actions).

## Exit codes

| Code | Means |
|---|---|
| 0 | done, even with warnings |
| 1 | a file could not be read or is not valid (template, data, `@FILE`), the template has an error (an unclosed section…), a limit was reached, or the output could not be written |
| 2 | wrong usage: unknown option, missing or extra argument, wrong extension, invalid `--set` key, output that would overwrite the template |
| 3 | `--strict`, and something was missing (a value, a section key, a picture) or a tag was not understood or not filled where it is: nothing was written |
