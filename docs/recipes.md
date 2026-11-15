# Recipes

- [Your company template from Markdown](#your-company-template-from-markdown)
- [Mail merge: one letter per customer, with a shell loop](#mail-merge-one-letter-per-customer-with-a-shell-loop)
- [Mail merge in parallel: xargs and GNU parallel](#mail-merge-in-parallel-xargs-and-gnu-parallel)
- [From a CSV file](#from-a-csv-file)
- [From a Python script](#from-a-python-script)
- [From Node.js](#from-nodejs)
- [In GitHub Actions](#in-github-actions)
- [In Docker](#in-docker)
- [Data written by an AI agent](#data-written-by-an-ai-agent)

Every recipe was run with `paginel-text` 0.3.0: the shell, Python and Node.js ones as written; the
GitHub Actions steps (in Ubuntu 22.04) and the Dockerfile with a local copy of the release archive in
place of the download.

## Your company template from Markdown

You write in Markdown; your company wants its Word template. One placeholder does it.

1. Open the company template (`.dotx` or `.docx`) in Word. Keep the cover page, the headers and
   footers, the logo. Delete the sample text and type, alone in a paragraph where the text should
   start:

   ```text
   {{body}}
   ```

   Add other placeholders where you want them: `{{title}}` in the cover's title, `{{date}}`,
   `{{author}}`.
2. Check that the paragraph holding `{{body}}` has the style you want for body text (*Normal*,
   *Body Text*…): the paragraphs of your Markdown take it.
3. Fill it:

   ```sh
   paginel-text fill company-template.dotx report.docx \
     --set body=@report.md --set title="Customer insights 2026" --set date="11 November 2026"
   ```

What you get: your `#` and `##` headings in the template's *Heading 1* and *Heading 2*, real Word
lists (nested, numbered), footnotes, tables, pictures (paths relative to `report.md`), quotes, page
breaks (`\newpage`). The cover, headers, footers and styles are those of the template, untouched.
Full example: [examples/04-report](../examples/04-report/).

Make it a PDF in the same step: `… report.pdf` instead of `report.docx` (see
[Limitations](limitations.md#pdf-output) about fonts).

## Mail merge: one letter per customer, with a shell loop

`customers.json` is a list:

```json
[
  { "id": "C001", "name": "Alex Morgan", "city": "Lyon", "amount": "120.00 EUR" },
  { "id": "C002", "name": "Sam Taylor", "city": "Nantes", "amount": "85.50 EUR" },
  { "id": "C003", "name": "Kim Lee", "city": "Lille" }
]
```

One letter per customer, with [jq](https://jqlang.org/):

```sh
mkdir -p out
jq -c '.[]' customers.json | while IFS= read -r customer; do
  id=$(printf '%s' "$customer" | jq -r .id)
  printf '%s' "$customer" | paginel-text fill letter.docx - "out/letter-$id.docx" --strict \
    || echo "letter $id failed" >&2
done
```

What it prints for the third customer, who has no `amount`:

```text
missing values (1): amount
data keys not used (1): id
--strict: 1 problem(s), nothing written
letter C003 failed
```

`--strict` makes a customer with a missing field fail loudly instead of producing a letter with a
gap. Write `.pdf` instead of `.docx` to get PDFs. Pictures named in the data are read from the
current folder, since the data comes on standard input.

## Mail merge in parallel: xargs and GNU parallel

Split the list into one file per customer, then fill several at a time:

```sh
mkdir -p data out
jq -c '.[]' customers.json | while IFS= read -r customer; do
  printf '%s' "$customer" > "data/$(printf '%s' "$customer" | jq -r .id).json"
done

# with xargs, 4 at a time
ls data/*.json | xargs -P 4 -I{} sh -c \
  'paginel-text fill letter.docx "$1" "out/$(basename "$1" .json).docx" --strict --base . || echo "$1 failed" >&2' _ {}

# or with GNU parallel, as PDFs
parallel -j 4 'paginel-text fill letter.docx {} out/{/.}.pdf --strict --base . || echo {} failed >&2' ::: data/*.json
```

`--base .` keeps picture paths relative to the current folder; without it, they would be read from
`data/`, the folder of each JSON file. Each run is independent: as many at a time as you have cores.

## From a CSV file

Convert it to JSON first, for example with Python:

```sh
python3 -c 'import csv, json, sys; json.dump(list(csv.DictReader(sys.stdin)), sys.stdout)' \
  < customers.csv > customers.json
```

Every CSV value becomes a string, which is what you want for printing. An empty cell becomes `""`,
which is present: `--strict` does not report it as missing.

## From a Python script

```python
#!/usr/bin/env python3
"""Makes one invoice per order, in parallel, and stops on the first error."""
import json
import subprocess
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

orders = json.loads(Path("orders.json").read_text(encoding="utf-8"))
Path("out").mkdir(exist_ok=True)


def invoice(order):
    data = {
        "invoice": {"number": order["number"], "date": order["date"]},
        "client": order["client"],
        "lines": [
            {"description": line["label"], "quantity": str(line["qty"]),
             "unit_price": f'{line["price"]:,.2f}', "amount": f'{line["qty"] * line["price"]:,.2f}'}
            for line in order["lines"]
        ],
    }
    total = sum(line["qty"] * line["price"] for line in order["lines"])
    data["totals"] = {"total": f"{total:,.2f}"}
    result = subprocess.run(
        ["paginel-text", "fill", "invoice-template.docx", "-", f'out/{order["number"]}.docx',
         "--strict", "--json"],
        input=json.dumps(data), capture_output=True, text=True,
    )
    report = json.loads(result.stdout) if result.stdout else {"ok": False}
    if not report["ok"]:
        raise RuntimeError(f'{order["number"]}: exit {result.returncode}: {result.stderr.strip()}')
    return report


with ThreadPoolExecutor(max_workers=4) as pool:
    reports = list(pool.map(invoice, orders))
print(f"{len(reports)} invoices written in out/")
```

The program does the arithmetic and the formatting (`f'{x:,.2f}'` gives `1,234.50`); the template
only places the values. The template here has `{{invoice.number}}`, `{{client.name}}`, a table row
`{{#lines}}{{description}} | {{quantity}} | {{unit_price}} | {{amount}}{{/lines}}` and
`{{totals.total}}`.

## From Node.js

```js
import { spawnSync } from "node:child_process";

const data = {
  invoice: { number: "2026-003", date: "13 November 2026" },
  client: { name: "Example Retail Ltd" },
  lines: [{ description: "Workshop", quantity: "1", unit_price: "900.00", amount: "900.00" }],
  totals: { total: "900.00" },
};
const result = spawnSync(
  "paginel-text",
  ["fill", "invoice-template.docx", "-", "out/2026-003.docx", "--strict", "--json"],
  { input: JSON.stringify(data), encoding: "utf8" },
);
const report = result.stdout ? JSON.parse(result.stdout) : { ok: false };
if (!report.ok) throw new Error(`exit ${result.status}: ${report.error?.message ?? result.stderr}`);
console.log(`${report.output}: ${report.filled} values`);
```

## In GitHub Actions

```yaml
name: Documents
on: [push]

jobs:
  build:
    runs-on: ubuntu-22.04
    steps:
      - uses: actions/checkout@v4

      - name: Install paginel-text
        env:
          VERSION: "0.3.0"
        run: |
          NAME=paginel-text-$VERSION-x86_64-unknown-linux-gnu
          BASE=https://github.com/paginel/paginel-cli/releases/download/v$VERSION
          curl -fsSLO "$BASE/$NAME.tar.gz"
          curl -fsSLO "$BASE/SHA256SUMS.txt"
          grep " $NAME.tar.gz\$" SHA256SUMS.txt | sha256sum -c -
          tar -xzf "$NAME.tar.gz"
          sudo install -m 755 "$NAME/paginel-text" /usr/local/bin/paginel-text
          paginel-text --version

      - name: Build the report
        run: |
          mkdir -p out
          paginel-text fill templates/report.docx data/report.json out/report.docx \
            --set body=@docs/report.md --strict
          paginel-text fill templates/report.docx data/report.json out/report.pdf \
            --set body=@docs/report.md --strict

      - uses: actions/upload-artifact@v4
        with:
          name: report
          path: out/
```

Pin `VERSION` so that a new release never changes your documents by surprise. The `ubuntu-latest`
runners work too (glibc 2.35 or later). `--strict` makes the job fail when the data and the template
drift apart.

## In Docker

The licence lets you put the unmodified binary in your images, with its `LICENSE` and
`THIRD-PARTY-LICENSES.txt`:

```dockerfile
FROM debian:12-slim
ARG VERSION=0.3.0
ARG NAME=paginel-text-${VERSION}-x86_64-unknown-linux-gnu
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates curl \
 && cd /tmp \
 && curl -fsSLO https://github.com/paginel/paginel-cli/releases/download/v${VERSION}/${NAME}.tar.gz \
 && curl -fsSLO https://github.com/paginel/paginel-cli/releases/download/v${VERSION}/SHA256SUMS.txt \
 && grep " ${NAME}.tar.gz\$" SHA256SUMS.txt | sha256sum -c - \
 && tar -xzf ${NAME}.tar.gz \
 && install -m 755 ${NAME}/paginel-text /usr/local/bin/paginel-text \
 && mkdir -p /usr/share/doc/paginel-text \
 && cp ${NAME}/LICENSE ${NAME}/THIRD-PARTY-LICENSES.txt /usr/share/doc/paginel-text/ \
 && rm -rf /tmp/* && apt-get purge -y curl && apt-get autoremove -y && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["paginel-text"]
```

```sh
docker build -t paginel-text .
mkdir -p out
docker run --rm -v "$PWD:/work" paginel-text fill template.docx data.json out/result.docx
```

The image needs no fonts and no network: the PDF fonts are inside the binary. Alpine (musl) is not
supported: use a glibc-based image (Debian 12, Ubuntu 22.04 or later).

## Data written by an AI agent

Give the agent the schema of the template, let it write the data, and let `--strict` check it:

```sh
paginel-text fields proposal.docx --schema > proposal.schema.json
# … the agent writes proposal.json, following the schema (values in Markdown)
paginel-text fill proposal.docx proposal.json out/proposal.docx --strict --json
```

The agent writes Markdown, which it is good at; the layout stays the template's. Pictures it names
are read only from the data's folder, nothing is downloaded, and a value is never read for tags. The
`--json` report tells it what was missing, unused or not understood, so it can fix its data and try
again. Links in its Markdown are written as given: check them if you publish the result.
