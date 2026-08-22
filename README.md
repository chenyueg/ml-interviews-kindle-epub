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
- builds from the Markdown source rather than scraping rendered web pages;
- creates EPUB3 with a clickable table of contents;
- preserves local images where Pandoc can resolve them;
- adds conservative reflowable CSS suitable for Kindle;
- retains the original book title and author metadata.

## Notes

Some formulas or images may render differently depending on Pandoc and Kindle's
conversion pipeline. The helper uses `gfm+tex_math_dollars` and EPUB3, which works
reasonably well for the source format but does not guarantee pixel-perfect
rendering.

## Copyright

*Machine Learning Interviews* and its contents are © Chip Huyen. This helper is
not affiliated with or endorsed by the author and does not include the book's
text. It automates a local conversion of the author's publicly available source.
