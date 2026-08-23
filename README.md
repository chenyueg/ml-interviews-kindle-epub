# Machine Learning Interviews → Kindle EPUB

A small PowerShell helper that builds a personal Kindle-friendly EPUB from
Chip Huyen's public [`ml-interviews-book`](https://github.com/chiphuyen/ml-interviews-book)
repository.

This repository **does not redistribute the book text**. The script fetches the
author's public source directly when you run it, then uses Pandoc to build an EPUB
for personal use.

## Requirements

- Windows PowerShell
- [Git](https://git-scm.com/download/win)
- [Pandoc](https://pandoc.org/)

Install Pandoc with WinGet:

```powershell
winget install --id JohnMacFarlane.Pandoc -e
```

Close and reopen PowerShell after installation.

## Usage

Clone or download this repository, then run:

```powershell
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
Unblock-File .\make-ml-interviews-epub.ps1
.\make-ml-interviews-epub.ps1
```

The execution-policy change applies only to the current PowerShell session.

By default, the EPUB is written to:

```text
~/Downloads/Machine-Learning-Interviews.epub
```

Choose another output path with:

```powershell
.\make-ml-interviews-epub.ps1 -Output "C:\Users\you\Desktop\ML-Interviews.epub"
```

Then upload the resulting EPUB with [Amazon Send to Kindle](https://www.amazon.com/sendtokindle).

## What the script does

- clones Chip Huyen's public `ml-interviews-book` repository;
- reads `SUMMARY.md` to preserve the GitBook/HonKit chapter order;
- uses the original `contents/images/mlib-cover.png` as the EPUB cover;
- removes the duplicate cover image from the temporary README used as the opening content page;
- builds from the Markdown source rather than scraping rendered web pages;
- creates EPUB3 with a clickable table of contents;
- includes each source directory in Pandoc's resource path so local images resolve correctly;
- converts LaTeX math to EPUB3 MathML;
- uses a small temporary Pandoc Lua filter to normalize multiline display equations;
- replaces paired decorative emoji in the book's callout headings with Kindle-safe text labels;
- gives `TIP`, `RESOURCES`, `PERSONAL STORY`, and `AMBIGUITY` distinct dark colors on color Kindle models;
- keeps every callout understandable on monochrome Kindle models because color is only an enhancement, not the only cue;
- adds conservative reflowable CSS suitable for Kindle;
- retains the original book title and author metadata.

## Callout styling

The source book uses paired emoji around several recurring labels. Some Kindle
fonts display those emoji as square "tofu" boxes, so the build normalizes them to
plain text and adds restrained color:

- `TIP` — dark green;
- `RESOURCES` — dark blue;
- `PERSONAL STORY` — dark purple;
- `AMBIGUITY` — dark red.

The palette is intentionally dark and moderately saturated for color e-ink. On a
monochrome Kindle, the labels remain bold text and therefore do not depend on hue
to carry meaning.

## Troubleshooting

If you previously saw many warnings such as:

```text
Could not fetch resource images/image18.png
Could not convert TeX math ... rendering as TeX
```

update to the latest version of the script. The image warnings were caused by
Pandoc resolving `images/...` relative to the repository root instead of the
Markdown files under `contents/`. The math warnings were caused by EPUB output
not explicitly using MathML plus a few display equations containing bare LaTeX
line breaks.

If callout headings such as `Tip`, `Resources`, or `Personal story` appeared with
square boxes on Kindle, those boxes were unsupported decorative emoji from the
source Markdown. The current build replaces the decorative markers while keeping
the semantic label.

Some unusual formulas may still render differently after Amazon's Kindle
conversion, but ordinary fractions, matrices, and multiline equations should be
preserved much more reliably.

## Copyright

*Machine Learning Interviews* and its contents are © Chip Huyen. This helper is
not affiliated with or endorsed by the author and does not include the book's
text. It automates a local conversion of the author's publicly available source.
