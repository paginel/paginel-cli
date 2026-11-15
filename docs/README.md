# paginel-text documentation

Start with the [README](../README.md) (install, quick start), then:

1. [Template syntax](template-syntax.md): the tags, how names are looked up, inline or block, empty
   and missing values.
2. [Markdown values](markdown-values.md): what a value can contain, and what Word receives.
3. [Pictures](images.md): paths and the base folder, formats, sizes, floating pictures, pictures in
   tables and headers, what happens when a picture cannot be used.
4. [Tables](tables.md): a Markdown table in a value (with Paginel's table notation), or a template
   table with repeated rows.
5. [Loops and conditions](loops-and-conditions.md): what repeats, contexts, nesting, errors.
6. [Where placeholders work](where-tags-work.md): body, tables, headers and footers, footnotes, text
   boxes, content controls, hyperlinks; and where they do not.
7. [Data](data.md): JSON, `--set`, standard input, the report; calling `paginel-text` from Python,
   Node.js, the shell, CI.
8. [Fields](fields.md): what a template expects, as a tree, JSON, a data skeleton or a JSON Schema.
9. [Command-line reference](cli-reference.md): every command, option, exit code, message, and the
   JSON output.
10. [Converting](convert.md): `paginel-text convert`, the Markdown front matter, `info` and `save`.
11. [Recipes](recipes.md): company template from Markdown, mail merge (loop, xargs, GNU parallel),
    CSV, Python, Node.js, GitHub Actions, Docker, AI agents.
12. [Limitations](limitations.md), [Troubleshooting](troubleshooting.md) (every message, its cause
    and its fix), [FAQ](faq.md).

Every page has examples you can copy; their results were produced by `paginel-text` itself. The
[examples](../examples/) folder has five complete ones, with their results.

This documentation is under the [MIT No Attribution](LICENSE) licence: copy what you need into your
own documentation.
