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
- creates EPUB3 with a clickable three-level table of contents;
- suppresses EPUB ordered-list markers in the TOC so Kindle does not show misleading auto-generated numbers next to the book's own section numbers;
- gives the TOC a book-like hierarchy: top-level parts, chapters, then sections;
- includes each source directory in Pandoc's resource path so local images resolve correctly;
- converts LaTeX math to EPUB3 MathML;
- uses a small temporary Pandoc Lua filter to normalize multiline display equations;
- normalizes both common Markdown spellings of paired decorative emoji callout headings, including variants such as `Tip for engineers...`;
- gives `TIP`, `RESOURCES`, `PERSONAL STORY`, and `AMBIGUITY` distinct dark colors on color Kindle models;
- keeps every callout understandable on monochrome Kindle models because color is only an enhancement, not the only cue;
- keeps ordinary blockquotes borderless so sections that use many consecutive quoted paragraphs do not turn into a stack of vertical rules;
- preserves external hyperlinks while removing Kindle's heavy full-sentence underlining and using restrained link color instead;
- adds conservative reflowable CSS suitable for Kindle;
- retains the original book title and author metadata.

## Table of contents

The EPUB keeps three TOC levels so it stays useful rather than becoming an
exhaustive wall of links: top-level book parts, chapters, and major numbered
sections. The source headings already contain meaningful numbering such as `1.1`,
`2.3`, and `5.2`.

EPUB3 navigation is structurally represented with an ordered list (`<ol>`).
Pandoc's default EPUB stylesheet normally hides those list markers, but supplying
a custom `--css` means that default TOC styling is no longer present. Without an
explicit replacement, Kindle may display unrelated `1, 2, 3...` list numbers in
front of each TOC link. This helper restores that behavior robustly by suppressing
markers and forcing TOC list items to ordinary blocks, while using indentation and
font weight for hierarchy. Top-level entries receive a restrained dark-blue accent
on color Kindle models; the hierarchy still works in monochrome.

## Callout styling

The source book uses paired emoji around several recurring labels and does not use
exactly one Markdown spelling everywhere. For example, a label may appear as
`🌳 **Tip** 🌳`, `**👱 Personal story 👱**`, or as the same construct inside a
blockquote and followed by `<br>`. Some Kindle fonts display those emoji as square
"tofu" boxes, so the build recognizes both major forms and normalizes them to text.

- `TIP` and longer `Tip for ...` variants — dark green;
- `RESOURCES` — dark blue;
- `PERSONAL STORY` — dark purple;
- `AMBIGUITY` — dark red.

The palette is intentionally dark and moderately saturated for color e-ink. On a
monochrome Kindle, the labels remain bold text and therefore do not depend on hue
to carry meaning.

## Blockquotes and links

The source occasionally uses blockquotes for several consecutive prose paragraphs.
A generic left-border style therefore produces many repeated vertical rules on a
Kindle page. This helper keeps blockquotes slightly indented but borderless.

The source also sometimes wraps a full sentence in an external hyperlink. Kindle's
default styling may underline every word in that sentence, which is visually heavy
on e-ink. Links remain clickable, but the helper uses restrained link color instead
of full underlining.

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

If every TOC hyperlink previously had an extra number that did not match the
chapter or section number, those were ordered-list markers from the EPUB
navigation structure, not book numbering. The current stylesheet removes them.

If callout headings such as `Tip`, `Resources`, or `Personal story` appeared with
square boxes on Kindle, those boxes were unsupported decorative emoji from the
source Markdown. The current build recognizes the blockquoted and standalone
variants rather than assuming one exact spelling.

Some unusual formulas may still render differently after Amazon's Kindle
conversion, but ordinary fractions, matrices, and multiline equations should be
preserved much more reliably.

## Copyright

*Machine Learning Interviews* and its contents are © Chip Huyen. This helper is
not affiliated with or endorsed by the author and does not include the book's
text. It automates a local conversion of the author's publicly available source.
