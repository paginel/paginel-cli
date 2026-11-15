# 04 — A report: your Markdown in your company template

The recipe most people want: **write in Markdown, get your company’s Word document**. The template
is a company report: a cover page without header, a logo and the title in the header of the other
pages, page numbers, the company’s fonts and colours. It has one `{{body}}` placeholder where the
whole report goes.

```sh
cd examples/04-report
mkdir -p out
paginel-text fill template.docx data.json out/report.docx --set body=@report.md
```

![Page 1 of out/report.docx](out/report.png)

The result: [out/report.docx](out/report.docx), and the same as a PDF: [out/report.pdf](out/report.pdf).

- `data.json` fills the cover: client, title, subtitle, author, date, reference.
- `--set body=@report.md` reads the value of `body` from the file `report.md`. Its pictures
  (`images/revenue.png`, `images/roadmap.png`) are read relative to the folder of `report.md`.

## What `report.md` uses

| Markdown | In Word |
|---|---|
| `#`, `##` | the template’s *Heading 1* and *Heading 2* (dark and light green, Arial) |
| nested `-` and `1.` lists | Word lists, nested |
| `[^method]` | a real footnote at the bottom of the page |
| a table with `<!-- table: widths 40% 30% 30% -->` | a Word table, columns at 40/30/30 % |
| `![…](images/revenue.png "width 90%")` | the chart at 90% of the text width |
| `\newpage` | a page break |
| `> …` | the template’s *Quote* style |
| `- [ ]`, `- [x]` | bullet items starting with ☐ and ☒ |

Paragraphs of the report take the style of the paragraph that held `{{body}}`, so the body text
looks like the rest of the template.

## Also in this template

- `{{#draft}}DRAFT — not for distribution{{/draft}}` on the cover: `"draft": false` removes it.
  Set `"draft": true` to see it.
- `{{&reference}}`: the reference `OA-2026-117_final` is plain text (an `_` would otherwise start
  italics in Markdown).
- The cover table (*Prepared for*, *Prepared by*…) has placeholders in its cells.

## Do it with your own template

1. Open your company template in Word, delete its sample text, and type `{{body}}` alone in a
   paragraph where the text should go (and `{{title}}`, `{{date}}`… where you want them).
2. Save it as `.docx` (a `.dotx` works too: the result is a `.docx`).
3. `paginel-text fill my-template.docx my-report.docx --set body=@my-report.md --set title="Q3 review"`

See [docs/recipes.md](../../docs/recipes.md) for more.
