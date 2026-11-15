# Loops and conditions

A **section** is a pair of tags with something between them:

- `{{#key}} … {{/key}}` shows its content **once per item** if `key` is a list, **once** if `key` is
  true, a non-empty text, a number or an object, and **not at all** if `key` is empty or missing;
- `{{^key}} … {{/key}}` (an **inverted** section) shows its content only if `key` is empty or missing.

Empty means: missing, `null`, `false`, `""`, `[]` or `{}`. The number `0`, the text `"0"` and the
text `"false"` are not empty. See [Empty, missing and false](template-syntax.md#empty-missing-and-false).

Every result on this page was produced by `paginel-text` and read back from the `.docx`.

## What repeats: where the tags are

The place of the two tags decides what is repeated or removed.

```text
Same paragraph            {{#tags}}{{.}}, {{/tags}}       → a piece of the paragraph repeats
Each alone in a paragraph {{#team}}                        → the paragraphs between them repeat
                          - {{name}}
                          {{/team}}
Two cells of one table    | {{#items}}{{name}} | {{price}}{{/items}} |   → table rows repeat
```

### Both tags in the same paragraph: a piece of the paragraph

```text
Tags: {{#tags}}{{.}} {{/tags}}
```

```json
{ "tags": ["design", "print", "web"] }
```

gives *Tags: design print web* (the text between the tags is repeated inside the paragraph). `{{.}}`
is the current item of a list of plain values; `{{#.}}…{{/.}}` tests it.

```text
Delivery {{#express}}(express, 24 h){{/express}}{{^express}}(standard, 3 days){{/express}}
```

with `"express": false` gives *Delivery (standard, 3 days)*.

A paragraph made only of sections that all come out empty is removed, so
`{{#draft}}DRAFT — not for distribution{{/draft}}` alone in its paragraph leaves no blank line.

### Each tag alone in its paragraph: blocks

```text
{{#team}}
• {{name}}, {{role}}            ← a bullet-list paragraph in Word
{{/team}}
```

```json
{ "team": [ { "name": "Ann", "role": "lead" }, { "name": "Bob", "role": "dev" } ] }
```

gives two list items, *Ann, lead* and *Bob, dev*. The paragraphs, list items, tables and pictures
between the two tag paragraphs are repeated for each item; the two tag paragraphs themselves
disappear. List items of the copies continue the same list: in Word, with *Steps before:* numbered
before the loop and *Step after* after it, you get 1. Steps before, 2. Step A, 3. Step B,
4. Step after.

Both tags must be in the **same container**: the body, the same table cell, the same header or
footer, the same text box.

A block loop that holds a **section break** (a chapter that ends in landscape, say, with the break
on the last paragraph before `{{/chapters}}`) repeats the break with each item: every copy keeps the
section's page settings, headers and footers. When the list is empty, the loop's section breaks go
with it, so no empty page is left, and the report warns:

```text
warning: section chapters has no item: its 1 section break(s) are removed with it (body, block 2: “{{#chapters}}”)
```

Content before the loop in the same section then takes the page settings of the section after the
loop.

A section break on the **closing** tag's paragraph (`{{/chapters}}` itself ends the section) is not
inside the loop: it ends the section that holds the whole loop. It is not repeated per item, and it
stays when the list is empty: if that section held only the loop, you get a blank page with its own
settings, without a warning. To repeat a section per item, put the break inside the loop, on the last
paragraph before `{{/chapters}}`.

**In a Markdown template** (`.md`), put each section tag alone on its own line. Blank lines around it
are optional: a line that holds only a section tag (or a comment) always stands alone, even in the
middle of a list.

```markdown
## Team

{{#team}}
- **{{name}}**, {{role}}
{{/team}}

1. Intro
{{#steps}}
1. Step {{name}}
{{/steps}}
1. Outro
```

The bullet list gives one list of two items. The numbered list gives 1. Intro, 2. Step A, 3. Step B,
4. Outro: the tag lines do not break it.

### Tags in two cells of a table: rows

```text
| {{#items}}{{name}} | {{price}}{{/items}} |
```

The rows from the one holding `{{#items}}` to the one holding `{{/items}}` are repeated, with their
table style. See [Tables](tables.md#2-a-template-table-with-repeated-rows).

### Anything else is an error

These are refused with exit code 1, nothing written, and a message giving the place (the part, the
block number counting from 1, and an excerpt of the paragraph) and how to fix it:

| Template | Message |
|---|---|
| `Members: {{#team}}`, then `{{/team}}` two paragraphs below | `section team shares a paragraph with text while its other tag is in another paragraph: put {{#team}} and {{/team}} in the same paragraph (repeated within the line), or each alone in its own paragraph (repeated paragraphs) (body, block 1: “Members: {{#team}}”)` |
| `{{#a}}` in the body, `{{/a}}` in a table cell | `{{/a}} closes nothing: {{#a}} is missing before it, in the same container (body, block 2, row 1, cell 1, block 1: “x{{/a}}”)` and `{{#a}} is never closed: …` |
| `{{#a}}` `{{#b}}` `{{/a}}` `{{/b}}`, each in its paragraph | `{{/a}} comes while {{#b}} is open: close {{/b}} first (sections nest, they do not cross) (body, block 3: “{{/a}}”)` and `{{#a}} is never closed: …` |
| `{{#a}}` and no `{{/a}}` | `{{#a}} is never closed: add {{/a}} in the same container (the body, the same cell, the same header), or in another cell of the same table to repeat rows (body, block 1: “{{#a}}”)` |
| `{{/a}}` and no `{{#a}}` | `{{/a}} closes nothing: {{#a}} is missing before it, in the same container (body, block 2: “{{/a}}”)` |
| `{{#a}}x` and `y{{/a}}` in two paragraphs of one cell | `section a opens and closes in the same cell, in two paragraphs: …` ([Tables](tables.md#row-loops-what-is-refused)) |
| 33 sections nested in one paragraph (`{{#a0}}{{#a1}}…{{#a32}}`) | `section a32 is nested more than 32 levels deep: simplify the template (body, block 1: “{{#a0}}{{#a1}}{{#a2}}{{#a3}}{{#a4}}{{#a5…”)` |
| a name of 33 segments (`{{s0.s1.….s32}}`) | `“{{s0.s1.s2.s3.s4.s5.s6.s7.s8.s9.s10.s11.…”: a key has at most 32 segments (a.b.c…) (body, block 1: “[{{s0.s1.s2.s3.s4.s5.s6.s7.s8.s9.s10.s11…”)` |

The full report starts with `template.docx: error in the tags:` and lists every error found, one per
line. With `--json`, each has a `code` (`section_spans_paragraphs`, `unexpected_close`,
`mismatched_close`, `unclosed_section`, `row_section_in_one_cell`, `row_sections_overlap`,
`sections_too_deep`, `key_too_long`), a `message` and a `where`
([the reference](cli-reference.md#json-output)).

## Sections over objects: a context

When the value is an object, the section shows once and the object becomes the **context**: names
inside are looked up in it first.

```text
{{#signature}}
{{name}}
{{title}}
{{/signature}}
{{^signature}}
The team
{{/signature}}
```

```json
{ "signature": { "name": "Camille Durand", "title": "Customer care" } }
```

gives *Camille Durand* / *Customer care*. Without `signature` in the data, *The team* shows instead
([examples/01-letter](../examples/01-letter/)).

A section over a plain value (a text or a number) shows once, and `{{.}}` is that value:
`{{#count}}count={{.}}{{/count}}` with `"count": 3` gives *count=3*.

## Nesting

Sections nest: an inline loop inside a row loop, a row loop inside a block loop, a block loop inside
a block loop.

```text
Ctx: {{#departments}}[{{name}}: {{#people}}{{name}}@{{city}} {{/people}}]{{/departments}}
```

```json
{ "city": "Lyon",
  "departments": [ { "name": "Sales", "people": [ { "name": "Ann", "city": "Paris" }, { "name": "Bob" } ] } ] }
```

gives *Ctx: [Sales: Ann@Paris Bob@Lyon ]*. Inside `people`, `{{name}}` is the person's name (the
innermost context wins); Bob has no `city`, so the lookup goes outwards to the root's. To reach the
department's name from inside `people`, give it another key (`dept_name`).

## Conditions

There is no `if`/`else` with comparisons: decide in the program that writes the data, and give the
template booleans or values.

```json
{ "overdue": true, "days_late": "12" }
```

```text
{{#overdue}}This invoice is {{days_late}} days overdue.{{/overdue}}
```

gives *This invoice is 12 days overdue.* For several cases, give one key per case
(`"status_paid": true`), or the text itself (`"status_text": "Paid on 3 March"`).

`--set` values are always strings: `--set overdue=false` is the **text** “false”, which is not empty,
so `{{#overdue}}` shows. Use JSON (`"overdue": false`) for booleans.

## Separators and the last item

Mustache has no “last item” test, so `{{#tags}}{{.}}, {{/tags}}` ends with a comma
(*design, print, web,* ). Join the list in your program instead (`"tags_text": "design, print and
web"`), or use a block loop where each item is its own paragraph or list item.

## Limits

- A list may have up to 100 000 items; a filled document up to 1 000 000 blocks. Beyond that the fill
  stops with exit code 1: `list items has 100001 items: 100000 at most`, or
  `the filled document would exceed 1000000 blocks: check the loops and the data`.
- Repetitions inside one paragraph are bounded too (500 000 in all), as is the text written (50
  million characters), so a loop nested in itself stops with a clear error instead of exhausting
  memory: `sections within lines would repeat more than 500000 times: check the nested loops and the
  data`, or `the filled document would exceed 50 million characters: check the loops and the data`
  (exit code 1).
