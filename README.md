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
- normalizes the original tree-emoji Tip markers to plain `TIP` labels so they render cleanly on both color and monochrome Kindle models;
- styles blockquotes with a simple current-color left border, requiring neither emoji fonts nor color support;
- adds conservative reflowable CSS suitable for Kindle;
- retains the original book title and author metadata.

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

If `Tip` headings appeared with square "tofu" boxes on Kindle, those boxes were
the original tree emoji characters. The current build replaces only that Tip
marker with a plain-text label and uses typography plus a left border for the
callout instead.

Some unusual formulas may still render differently after Amazon's Kindle
conversion, but ordinary fractions, matrices, and multiline equations should be
preserved much more reliably.

## Copyright

*Machine Learning Interviews* and its contents are © Chip Huyen. This helper is
not affiliated with or endorsed by the author and does not include the book's
text. It automates a local conversion of the author's publicly available source.
