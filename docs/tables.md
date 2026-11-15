# Tables

There are two ways to get a table, and you will use both:

| | A Markdown table in a value | A template table with repeated rows |
|---|---|---|
| The table is | made from the data | drawn in the template |
| Columns | decided by the data | decided by the template |
| Look | thin grid, or Paginel's table notation | **the template's table style**, borders, widths, fonts |
| Best for | free-form tables in a report | invoices, price lists, anything that must look like your brand |

[examples/03-tables](../examples/03-tables/) shows both, in an invoice. Every result on this page was
read back from the `.docx` written by `paginel-text`.

## 1. A Markdown table in a value

Put the placeholder **alone in its paragraph**, and give it a GitHub-style table:

```json
{ "summary": "| Phase | Days | Amount |\n|---|---:|:---:|\n| Workshop | 1 | 900.00 |\n| Design *x* | 4 | 2,400.00 |" }
```

What Word receives:

- a new table **across the text width** (on an A4 page with 2.5 cm margins: 16 cm), columns of
  equal width, a thin grid;
- the **header row in bold**;
- `---:` aligns a column's cells to the right, `:---:` centres them, `:---` or `---` leaves them on
  the left;
- cells hold inline Markdown (bold, italics, links, footnotes) and pictures; `<br>` is a line break
  in the cell, and `<br data-p>` starts a new paragraph in it. A cell cannot hold a list;
- when the value is only a table, the placeholder's paragraph stays after it, empty (with its
  style); it does not when the value also has text before or after the table.

### Paginel's table notation

GitHub tables say nothing about widths or colours. Paginel adds HTML comments, which GitHub and other
Markdown tools ignore, so the table stays readable everywhere:

```markdown
<!-- table: widths 50% 25% 25%; borders 0.5pt #808080 -->
| <!-- cell: fill #DEEAF6 --> Phase | <!-- cell: fill #DEEAF6 --> Days | <!-- cell: fill #DEEAF6 --> Amount |
|---|---:|---:|
| Workshop | 1 | 900.00 |
| **Total** | < | **900.00** |
| ^ | x | ![](images/a.png "width 1cm") |
```

gives a table with columns at 50/25/25 % of the text width, grey borders, a shaded header row,
*Total* spanning two columns, and the first cell of the last row merged into the cell above.

On the line before the table, `<!-- table: … -->` takes, separated by `;`:

| Key | Values |
|---|---|
| `widths` (or `columns`) | one per column: percentages (`30% 70%`), lengths (`4cm 8cm`), or bare numbers as proportions (`1 2 1`) |
| `width` | the table's width: `auto`, a percentage of the text width, or a length |
| `align` | where the table sits: `left`, `center`, `right` |
| `indent` | a left indent (a length) |
| any `cell:` key below | the default for every cell |

In a cell, `<!-- cell: … -->` takes:

| Key | Values |
|---|---|
| `fill` (or `background`) | a background colour `#RRGGBB`, or `none` |
| `valign` | `top`, `middle` (or `center`), `bottom` |
| `borders` (or `border`) | `none`; one border for all sides, `0.5pt #000000`; or four separated by `/`, top first |
| `padding` | one, two or four lengths |
| `align` | the alignment of its text: `left`, `center`, `right`, `justify` |
| `height` | the height of its row; add `exact` for a fixed height |

Merged cells: `<` alone in a cell merges it with the cell on its left; `^` alone with the cell above
(write `\<` or `\^` for the characters themselves). `<!-- -->` at the start of a row leaves a grid
column empty before its first cell; at its end, a cell is missing.

Lengths: `pt` (or a bare number), `cm`, `mm`, `in`.

### What a Markdown table does not do

- It does **not** use a Word table style: it gets a thin grid, or what the notation says. When the
  table must match your template, draw it in the template (way 2).
- In an **inline** placeholder (with text around it), a table cannot be placed: its text is written
  with tabs between cells and a line break between rows, with a warning.
- In headers, footers and footnotes, a table is turned into paragraphs, with a warning.
- In a **table cell** of the template, a Markdown table value becomes a nested table. Its width is an
  equal share of the template table (the table's width divided by its number of columns), so with
  uneven columns it can be narrower or wider than its cell. Its pictures are sized from the template
  cell instead: `%` is a share of that cell's width divided by the value table's columns. In a 16 cm
  template table of a 3 cm and a 13 cm column, a two-column value table is 7.62 cm wide in either
  cell; a `width 100%` picture in it is 0.93 cm wide in the 3 cm cell, and a `width 50%` one 2.96 cm
  in the 13 cm cell.

## 2. A template table with repeated rows

Draw the table in Word, with your table style, header row, borders and widths. In the row to
repeat, put `{{#items}}` at the start of its **first cell** and `{{/items}}` at the end of its
**last cell**:

| Description | Amount |
|---|---|
| `{{#lines}}{{description}}` | `{{amount}}{{/lines}}` |
| Total | `{{total}}` |

```json
{
  "lines": [
    { "description": "Workshop", "amount": "900.00" },
    { "description": "**Logo**", "amount": "2,400.00" }
  ],
  "total": "3,300.00"
}
```

Result (read back):

| Description | Amount |
|---|---|
| Workshop | 900.00 |
| **Logo** | 2,400.00 |
| Total | 3,300.00 |

- The row is copied **once per item**, and `{{description}}`, `{{amount}}`… are read in the item
  (then in the data around it, see [name lookup](template-syntax.md#how-a-name-is-looked-up)).
- The copies keep everything the row had: table style, banding, borders, shading, widths, height,
  alignment, fonts. A header row that repeats on each page keeps doing so.
- The `{{#lines}}` and `{{/lines}}` tags are removed from the cells.
- Rows before and after (header, totals) are not repeated.
- With an **empty list** (`[]`), the row is **removed**; the header and total rows stay. A table left
  with no row at all is removed.
- A **missing** list key behaves like an empty list, but `--strict` fails on it: a misspelt key
  should not silently give an invoice without lines.
- **Several rows** can repeat together: put `{{/lines}}` in the last cell of a later row. Each item
  then gets that group of rows (a two-line entry, a row and its comment row…):

  | | |
  |---|---|
  | `{{#items}}{{name}}` | `{{price}}` |
  | `{{note}}` | `{{/items}}` |

  with two items gives *A, 1 / note A / B, 2 / note B*: four rows.
- Cells can hold any placeholder: inline values, block values (paragraphs, lists, pictures), even a
  section over paragraphs inside the cell. A placeholder that is alone in its cell once the loop tags
  are removed is a block placeholder.
- Merged cells: a vertical merge that spans the loop rows is kept; when the rows of a loop are
  removed, a merge that started in them is closed cleanly.

`paginel-text` does not compute: totals, taxes and counts come with the data, computed by the
program that writes it.

### Row loops: what is refused

- `{{#items}}` and `{{/items}}` in the **same cell**, in two paragraphs: that would repeat paragraphs
  of the cell, not rows. Exit code 1:

  ```text
  section a opens and closes in the same cell, in two paragraphs: to repeat table rows, put {{#a}} in the first cell and {{/a}} in the last one; to repeat paragraphs of the cell, put each tag alone in its own paragraph (body, block 1, row 1, cell 1, block 2: “y{{/a}}”)
  ```

- two row loops sharing a row (unless one is inside the other): `row section b overlaps another row
  section: two row sections never share a row unless one is inside the other (…)`;
- the opening tag in a cell and the closing tag outside the table (or the other way round);
- a row loop in a table of a **header or footer**: not supported there. Exit code 1:

  ```text
  section items shares a paragraph with text while its other tag is in another paragraph: put {{#items}} and {{/items}} in the same paragraph (repeated within the line), or each alone in its own paragraph (repeated paragraphs). In a header or footer, table rows are not repeated (not supported): a row loop goes in the body (header, block 1: “{{#items}}{{name}}”)
  ```

## Combining loops and tables

- **One table per item**: put the whole table between `{{#groups}}` and `{{/groups}}` paragraphs
  (each tag alone in its paragraph, above and below the table). See
  [Loops and conditions](loops-and-conditions.md).
- **Rows inside a repeated table**: a row loop inside a block loop works: each group gets its
  heading and its table, each table its rows.

  ```text
  {{#groups}}
  {{gname}}                                  ← a Heading 2 paragraph
  | Person                  | Phone                   |
  | {{#people}}{{name}}     | {{phone}}{{/people}}    |
  {{/groups}}
  ```

  with `{"groups": [{"gname": "Sales", "people": [{"name": "Ann", "phone": "1"}, {"name": "Bob", "phone": "2"}]}, {"gname": "Support", "people": [{"name": "Cid", "phone": "3"}]}]}`
  gives *Sales* with a 3-row table, then *Support* with a 2-row table.
- **A message when the list is empty**: `{{^lines}}No line items.{{/lines}}` in a paragraph after the
  table. With items, that paragraph disappears entirely.
