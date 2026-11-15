# Examples

Each folder holds a template, its data, a `README.md` that explains what to look at, and the result,
made with the released binary (`out/`).

| Folder | Shows |
|---|---|
| [01-letter](01-letter/) | text values: in a sentence, with bold, italics and links, a whole block (heading and lists), plain text, headers and footers, a conditional signature |
| [02-images](02-images/) | pictures: a logo in the header, natural size, `width 5cm`, `width 50%`, a floating picture with text around it, pictures in table cells |
| [03-tables](03-tables/) | tables: a Markdown table in a value, a styled invoice table with a repeated row, totals, an empty list |
| [04-report](04-report/) | your Markdown report in your company’s Word template: one `{{body}}`, filled from a file |
| [05-markdown-template](05-markdown-template/) | a Markdown template (in French) with a front matter, to Word, PDF or Markdown |

## Run them all

From the `examples` folder, with `paginel-text` on your `PATH`:

```sh
for dir in */; do
  (cd "$dir" && mkdir -p out && paginel-text $(cat command.txt))
done
```

`command.txt` holds the arguments of each example, the same as in its README. `check.json` lists what
the result must contain; Paginel’s own tests run every example against it before a release, so the
commands in these pages work with the version they were published with.

## Licence

The examples (templates, data, pictures, Markdown) are under the [MIT No Attribution](LICENSE)
licence: copy them, change them, use them in your own projects, no need to credit anyone. All names,
companies and addresses in them are invented.
