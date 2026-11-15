# FAQ

**Do I need Word?**
No. `paginel-text` reads and writes `.docx` itself. You need Word (or LibreOffice, or the
[Paginel app](https://github.com/paginel/paginel-text)) only to design the template and to open the
result. A Markdown template (`.md`) needs no word processor at all.

**Does the result open in LibreOffice, Google Docs, Pages?**
The result is a standard `.docx`. The five examples were opened in Microsoft Word, which asked for no
repair, and in LibreOffice, with the same page counts in both; Google Docs and Pages were not tried.
What looks exactly as designed is what your template looks like in that program.

**Which systems does it run on?**
Linux x86_64 (glibc 2.35 or later) and Windows 10 and 11 (x64). There is no macOS build in 0.3.0:
it comes in a later version. On Windows, read [Windows PowerShell 5.1](data.md#windows-powershell-51)
before piping JSON into `paginel-text`: accented keys can be lost on the way.

**Is it free? Can I use it at work, on a server, in CI, in a commercial product?**
Yes to all. The binary is free to use and to put in container and CI images (see [LICENSE](../LICENSE)).
It is proprietary: you may not modify it or sell it. The documentation and examples are MIT-0: copy
them freely.

**Is the source code available?**
No. `paginel-text` is built from the engine of the Paginel app, which is not open source.

**Does it send my documents anywhere?**
No. `paginel-text` works entirely offline: it contains no networking code and never opens a network
connection itself. No telemetry, no metrics, no update check, no account, no online service. It
reads only the files you give it and the pictures they name, and writes only the output file you ask
for (no cache, no configuration, no log). Pictures given as web addresses are never downloaded:
`![…](https://…)` becomes a grey “image to provide” frame, with a warning, and an HTML `<img>` is
left out, with no frame and no warning ([Pictures](images.md)). Good to know: if a file or
picture path points to a network share (on Windows, for example `\\server\share\logo.png` or
`//server/share/logo.png`), your operating system fetches it from that share, as it would for any
program. See [Privacy](../README.md#privacy-works-offline).

**Does it work on a computer without network access?**
Yes: copy the archive there and check it against `SHA256SUMS.txt`. Everything `paginel-text` needs
is in the binary, the fonts of its PDFs included, and it reads no proxy settings, since it connects
to nothing. To see it on Linux: `strace -f -qq -e trace=network -o net.log paginel-text fill
template.docx data.json out.docx` leaves `net.log` empty.

**Is it safe to fill templates with data from users or AI agents?**
It was built for that: pictures are read only from the data's folder unless you allow more, web
addresses are never fetched, a value is never read for tags, sizes are bounded (50 MiB of data,
20 MiB per picture, 100 000 items per list), and nothing is written but the output you name. Links
in the data are written as given: check them if the result is published. See [SECURITY.md](../SECURITY.md).

**Why Markdown values instead of plain strings?**
Because most values are not just strings: a name in bold, a link, a list of conditions, a table, a
whole report. With Markdown, the data says *what* it is (a heading, a list) and the template says
*how it looks* (its styles). And programs, and AI models, write Markdown well. When you want a plain
string, use `{{&key}}`.

**Is it compatible with Mustache? With docxtemplater, python-docx-template, Word's mail merge?**
The tags are Mustache's (`{{key}}`, `{{#section}}`, `{{^inverted}}`, `{{! comment}}`, `{{&raw}}`,
`{{{raw}}}`, `{{.}}`), with Mustache's context stack, without partials, lambdas and delimiter
changes. Templates made for other tools need their tags changed: docxtemplater uses single braces by
default and its own loop syntax for rows, python-docx-template uses Jinja (`{% for %}`), Word's mail
merge uses `MERGEFIELD` fields, which `paginel-text` does not read.

**How do I format a number, a date, a currency?**
In the program that writes the data, and send a string. `paginel-text` writes values as given, and
normalises JSON numbers (`19.90` → `19.9`).

**How do I compute a total?**
In the program that writes the data, too. Templates have no arithmetic.

**How do I show something only if a value has a given value?**
Give the template a boolean or a text for it: `"is_overdue": true`, then
`{{#is_overdue}}…{{/is_overdue}}`. There are no comparisons in templates.

**Can I fill a PDF form?**
No. `paginel-text` writes PDFs, it does not fill them.

**Can the data come from a database, a CSV, a spreadsheet?**
Through JSON: export or convert to JSON, then pass it as a file or on standard input. See
[Data](data.md) and the [recipes](recipes.md#from-a-csv-file).

**Can a value contain placeholders?**
No: values are not read for tags. A value `"{{name}}"` is written as `{{name}}`.

**How do I write a literal `{{` in the result?**
Put it in a value and use `{{&key}}`. In the template itself, `{{` followed by something that is not
a tag is left as it is (with a warning).

**Can I fill a template in two passes?**
Yes: `--keep-missing` leaves the tags without a value in place, so the output is a template again.

**Can I use a template stored online (SharePoint, Google Drive)?**
Download it first: `paginel-text` reads local files only.

**How fast is it?**
On a 6-core desktop processor (AMD Ryzen 5 5500, Linux), each example fills in under 0.02 s to a
`.docx`, and in 0.04 s to a PDF for the three-page report with pictures. A 5 000-row table loop takes
0.07 s to a `.docx` and 0.35 s to a 105-page PDF. Run several in parallel for large batches
([recipe](recipes.md#mail-merge-in-parallel-xargs-and-gnu-parallel)).

**Which version am I running?**
`paginel-text --version`. Its version number follows the Paginel app's: both are built from the same
engine.

**What is Paginel?**
A word processor that complements Word and Google Docs: your `.docx` stay `.docx`, and AI agents
write in them too. `paginel-text` is its engine on the command line. [paginel.com](https://paginel.com).
