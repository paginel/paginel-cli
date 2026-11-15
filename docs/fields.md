# Fields: what a template expects

`paginel-text fields` reads a template without filling it and lists its placeholders: the same walk
as `fill` (body, table cells, headers and footers of every kind, footnotes, text boxes). Use it to
check a template after editing it in Word, to start a data file, or to give a program or an AI agent
the shape of the data to produce.

```sh
paginel-text fields template.docx                     # a readable tree
paginel-text fields template.docx --json              # the tree as JSON
paginel-text fields template.docx --example > data.json   # a data skeleton
paginel-text fields template.docx --schema > schema.json  # a JSON Schema of the data
```

The three options exclude each other (`--schema, --example and --json exclude each other`, exit code
2). A template with an error in its tags is reported as by `fill`, with exit code 1. The outputs
below are those of [examples/03-tables](../examples/03-tables/) and
[examples/01-letter](../examples/01-letter/), pasted from the binary.

## The tree

```text
$ paginel-text fields template.docx
invoice.number   Markdown, inline [body, header]
invoice.date     Markdown, inline [body]
invoice.due      Markdown, inline [body]
client.name      Markdown, block (paragraphs, lists, tables, images) [body]
client.street    Markdown, block (paragraphs, lists, tables, images) [body]
client.city      Markdown, block (paragraphs, lists, tables, images) [body]
summary          Markdown, block (paragraphs, lists, tables, images) [body]
#lines           section: table rows repeated [body, table]
  description    Markdown, block (paragraphs, lists, tables, images) [table]
  quantity       Markdown, block (paragraphs, lists, tables, images) [table]
  unit_price     Markdown, block (paragraphs, lists, tables, images) [table]
  amount         Markdown, block (paragraphs, lists, tables, images) [table]
totals.subtotal  Markdown, block (paragraphs, lists, tables, images) [table]
totals.vat       Markdown, block (paragraphs, lists, tables, images) [table]
totals.total     Markdown, block (paragraphs, lists, tables, images) [body, table]
#payments        section: table rows repeated [body, table]
  date           Markdown, block (paragraphs, lists, tables, images) [table]
  method         Markdown, block (paragraphs, lists, tables, images) [table]
  amount         Markdown, block (paragraphs, lists, tables, images) [table]
&company.iban    plain text [body]
company.name     Markdown, inline [footer]
company.address  Markdown, inline [footer]
company.vat      Markdown, inline [footer]
```

One line per key, in the order of the document, each key once:

- `#name` is a section, `^name` an inverted section, `&name` a plain-text value; the keys used inside
  a section are indented under it. The keys inside an inverted section are not: it is shown only when
  its key is false, empty or missing, so they come from the data around it, and they are listed at
  its level (`{{^draft}}…{{client}}{{/draft}}` gives `^draft` then `client`);
- *Markdown, inline*: the placeholder shares its paragraph with text (inline Markdown only);
  *Markdown, block*: it is alone in its paragraph (blocks allowed); *plain text*: `{{&…}}`;
- *section: table rows repeated*, *section: paragraphs repeated* or *section: repeated within the
  line*; an inverted section reads *inverted condition (shown when false, empty or missing)*;
- between brackets, where it was found: `body`, `table` (a table cell), `header`, `footer`,
  `first-header`, `first-footer`, `even-header`, `even-footer`, `footnote` (a text box counts as the
  place that holds it: `body` for a box in the body); and `endnote`, `comment`, `field-code` for tags
  the fill leaves as typed: a key found only there ends with *— not filled there*, and is left out of
  `--schema` and `--example`. `fields` also prints a warning for each of these tags.

A key used both inside a section and outside it is listed in both places: Mustache looks it up in
the item first, then outside.

## `--json`

The same tree, as a list of objects `{name, kind, placement, where, children}`:

```json
[
  {
    "children": [
      { "children": [], "kind": "value", "name": "description", "placement": "block", "where": ["table"] },
      { "children": [], "kind": "value", "name": "quantity", "placement": "block", "where": ["table"] },
      { "children": [], "kind": "value", "name": "unit_price", "placement": "block", "where": ["table"] },
      { "children": [], "kind": "value", "name": "amount", "placement": "block", "where": ["table"] }
    ],
    "kind": "section",
    "name": "lines",
    "placement": "rows",
    "where": ["body", "table"]
  },
  { "children": [], "kind": "text", "name": "company.iban", "placement": "inline", "where": ["body"] }
]
```

| Field | Values |
|---|---|
| `name` | the key as written (`client.name`), without `#`, `^` or `&` |
| `kind` | `value` (`{{key}}`), `text` (`{{&key}}`), `section` (`{{#key}}`), `inverted` (`{{^key}}`) |
| `placement` | `inline`, `block` for values; `inline`, `paragraphs`, `rows` for sections |
| `where` | the places listed above |
| `children` | the tags inside a section |

(The objects above are shown on one line each to save space; the binary prints them indented, with
keys in alphabetical order.)

## `--example`: a data skeleton

```json
$ paginel-text fields template.docx --example
{
  "invoice": {
    "number": "…",
    "date": "…",
    "due": "…"
  },
  "client": {
    "name": "…",
    "street": "…",
    "city": "…"
  },
  "summary": "…",
  "lines": [
    {
      "description": "…",
      "quantity": "…",
      "unit_price": "…",
      "amount": "…"
    }
  ],
  "totals": {
    "subtotal": "…",
    "vat": "…",
    "total": "…"
  },
  "payments": [
    {
      "date": "…",
      "method": "…",
      "amount": "…"
    }
  ],
  "company": {
    "iban": "…",
    "name": "…",
    "address": "…",
    "vat": "…"
  }
}
```

- every value is `"…"`; dotted keys become nested objects;
- a section with keys inside is a list of one item (an object section like `signature` in
  example 01 too: a one-item list works the same as an object);
- a section with nothing inside (a condition such as `{{#draft}}`) is `true`; an inverted section
  is `false`, and the keys inside it sit beside it: `{{^draft}}…{{client}}{{/draft}}` gives
  `{"draft": false, "client": "…"}`;
- a section that is also the parent of a dotted key (`{{a.x}}` beside
  `{{#a}}{{#b}}{{y}}{{/b}}{{/a}}`) is one object that holds both:
  `{"a": {"x": "…", "b": [{"y": "…"}]}}`.

The skeleton fills back without error, even with `--strict`: `paginel-text fill template.docx
data.json out.docx --strict` on it writes every placeholder with “…”.

## `--schema`: a JSON Schema

A JSON Schema (draft 2020-12) of the data, to validate data before filling, or to give to a program
or a model that writes the data:

```json
{
  "$defs": {
    "lines": {
      "properties": {
        "amount": {
          "description": "Markdown, block (paragraphs, lists, tables, images)",
          "type": [
            "string",
            "number",
            "boolean"
          ]
        }
      }
    }
  },
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "properties": {
    "client": {
      "properties": {
        "city": {
          "description": "Markdown, block (paragraphs, lists, tables, images)",
          "type": [
            "string",
            "number",
            "boolean"
          ]
        }
      },
      "type": "object"
    },
    "lines": {
      "$ref": "#/$defs/lines",
      "description": "section: table rows repeated for each item",
      "items": {
        "$ref": "#/$defs/lines",
        "type": "object"
      },
      "type": [
        "array",
        "object",
        "boolean"
      ]
    },
    "summary": {
      "description": "Markdown, block (paragraphs, lists, tables, images)",
      "type": [
        "string",
        "number",
        "boolean"
      ]
    }
  },
  "type": "object"
}
```

(Shortened from the output for [examples/03-tables](../examples/03-tables/): one key of `client`
and of the `lines` items is kept, and `payments`, `invoice`, `totals` and `company` are left out. The
binary prints keys in alphabetical order.)

- values are `"type": ["string", "number", "boolean"]`, with a `description` saying *Markdown,
  inline*, *Markdown, block (paragraphs, lists, tables, images)* or *plain text*;
- sections are `"type": ["array", "object", "boolean"]`, with a `description` saying what repeats;
  the keys inside a section are described once, under `$defs` (named after the section's key, with
  its parents' keys for a nested section: `a.b`), and referred to by `$ref` from its `items` (a list)
  and from the section itself (a single object); a section over plain values (`{{.}}`) has `items` of
  type string, number or boolean;
- an inverted section (`{{^key}}`) has only a `description` (any value is accepted); the keys inside
  it are described beside it;
- nested objects (`client.name`) are objects with `properties`;
- a section that is also the parent of a dotted key (`{{a.x}}` and `{{#a}}…{{/a}}`) is
  `"type": "object"`, with a `$ref` for the keys used inside the section and its own `properties`
  for the dotted keys (`x`);
- there is no `required`: a missing key is allowed by the schema (use `fill --strict` to refuse it);
- each section is described once, however deeply it is nested, so the size of the schema follows
  the number of tags.

With Python's `jsonschema` package, for example:

```python
import json, jsonschema
jsonschema.validate(json.load(open("data.json")), json.load(open("schema.json")))
```

## For AI agents

```sh
paginel-text fields proposal.docx --schema > proposal.schema.json
# the agent writes proposal.json following the schema, values in Markdown
paginel-text fill proposal.docx proposal.json out/proposal.docx --strict --json
```

The `--json` report of `fill` tells the agent what was missing, unused or not understood, so it can
fix its data and try again ([recipe](recipes.md#data-written-by-an-ai-agent)).
