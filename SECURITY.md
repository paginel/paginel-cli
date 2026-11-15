# Security

`paginel-text` is built to run on data that comes from other programs, other people or AI agents:

- it works entirely offline: it contains no networking code and never opens a network connection
  itself (no telemetry, no metrics, no update check, no account, no online service), and a picture
  given as a web address is never downloaded: `![…](https://…)` becomes a grey “image to provide”
  frame, with a warning ([Privacy](README.md#privacy-works-offline)); an HTML `<img src="…">`, local
  or web, is not read at all: it is left out silently, with no frame, and `--strict` does not catch
  it ([Pictures](docs/images.md));
- a path that points to a network share (on Windows, for example `\\server\share\logo.png` or
  `//server/share/logo.png`) is opened like any file, so your operating system fetches it from that
  share, as it would for any program. Pictures named in the data cannot point there unless you pass
  `--allow-any-path`; a Markdown file you `convert` (or give to `info`, `dump` or `save`) and the
  pictures typed in a `.md` template can: on Windows, check Markdown that someone else wrote before
  converting it;
- it reads the pictures named in the data only from the data's folder (or the folder given with
  `--base`), after resolving `..` and symbolic links, unless you pass `--allow-any-path`; the pictures
  of a Markdown template itself are read like `convert` reads them (the template is your own file);
- a value is never read for tags, so data cannot add placeholders;
- links in values are written as given, whatever their scheme (`https:`, `mailto:`, `file:`…): check
  them when the data is not trusted and the document is published;
- it reads at most 20 MiB per picture and 50 MiB of JSON data, reads a Word file's parts within size
  limits (a “zip bomb” is refused), refuses sections nested more than 32 deep, and stops on lists of
  more than 100 000 items, documents of more than 1 000 000 blocks or 50 million characters;
- it writes only the output file you name (through a temporary file in the same folder, renamed at
  the end, so a failed run leaves an existing output untouched), and never over the template, even
  through a link.

## Reporting a vulnerability

Please write to **hello@paginel.com** with “security” in the subject, and do not open a public issue.
Say which version (`paginel-text --version`) and system, and how to reproduce the problem; attach the
smallest template and data that show it, with nothing confidential in them.

We answer within a week. When a fix is released, the release notes say so, with your name if you
wish.

## Supported versions

Only the latest release receives fixes.

---

**Français** : pour signaler une faille, écrivez à **hello@paginel.com** (objet « sécurité »), sans
ouvrir de ticket public. Seule la dernière version est corrigée.
