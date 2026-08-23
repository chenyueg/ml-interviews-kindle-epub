param(
    [string]$Output = "$HOME\Downloads\Machine-Learning-Interviews.epub"
)

$ErrorActionPreference = "Stop"

function Need-Command($name, $installHint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host ""
        Write-Host "Missing dependency: $name" -ForegroundColor Yellow
        Write-Host $installHint
        exit 1
    }
}

Need-Command "git" "Install Git for Windows: https://git-scm.com/download/win"
Need-Command "pandoc" "Install Pandoc: winget install --id JohnMacFarlane.Pandoc -e"

$work = Join-Path $env:TEMP "ml-interviews-book-kindle"
if (Test-Path $work) { Remove-Item -Recurse -Force $work }

Write-Host "Cloning Chip Huyen's public repository..."
& git clone --depth 1 https://github.com/chiphuyen/ml-interviews-book.git $work
if ($LASTEXITCODE -ne 0) {
    throw "git clone failed with exit code $LASTEXITCODE."
}

Set-Location $work

if (-not (Test-Path "SUMMARY.md")) {
    throw "SUMMARY.md not found."
}

# Use the original cover image shipped in the author's repository.
$coverPath = Join-Path $work "contents\images\mlib-cover.png"
if (-not (Test-Path $coverPath)) {
    throw "Book cover not found at contents/images/mlib-cover.png."
}

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)

# README already displays the same cover image at the top. Build a temporary
# Kindle copy without that first image so the formal EPUB cover is not repeated.
$kindleReadme = "README-kindle.md"
if (Test-Path "README.md") {
    $readme = Get-Content "README.md" -Raw -Encoding UTF8
    $readme = [regex]::Replace(
        $readme,
        '(?s)^\s*<p\s+align="center">\s*<img[^>]*mlib-cover\.png[^>]*/?>\s*</p>\s*',
        ''
    )
    [System.IO.File]::WriteAllText((Join-Path $work $kindleReadme), $readme, $utf8NoBom)
}

# Parse Markdown paths from GitBook/HonKit SUMMARY.md in reading order.
$summary = Get-Content "SUMMARY.md" -Raw -Encoding UTF8
$matches = [regex]::Matches($summary, '\[[^\]]+\]\(([^)]+\.md)\)')
$files = @()

foreach ($m in $matches) {
    $p = $m.Groups[1].Value
    if ($p -match '^(https?://|#)') { continue }
    $p = [System.Uri]::UnescapeDataString($p)
    if (Test-Path $p) {
        $files += $p
    }
}
$files = $files | Select-Object -Unique

# The source uses several paired emoji as decorative callout markers, with more
# than one Markdown spelling (emoji outside bold text, emoji inside bold text,
# blockquoted or standalone, sometimes followed by <br>). Some Kindle fonts
# render those emoji as tofu boxes. Normalize every known callout family while
# preserving variable labels such as "Tip for engineers early in your careers".
# The script source itself uses Unicode code points rather than literal emoji so
# Windows PowerShell 5.1 does not depend on the script file's BOM for parsing.
$tree = [regex]::Escape([System.Char]::ConvertFromUtf32(0x1F333))       # tree
$wave = [regex]::Escape([System.Char]::ConvertFromUtf32(0x1F30A))       # water wave
$person = [regex]::Escape([System.Char]::ConvertFromUtf32(0x1F471))     # blond person
$warning = [regex]::Escape([System.Char]::ConvertFromUtf32(0x26A0))     # warning sign

# Form A: > emoji **Label** emoji<br>
# Form B: > **emoji Label emoji**<br>
# The optional quote capture is preserved, so the source's semantic blockquote
# remains intact while the unsupported decorative glyphs disappear.
$tipInnerPattern = '(?m)^(?<quote>>\s*)?' + $tree + '\s*\*\*(?<label>Tip[^*\r\n<]*?)\*\*\s*' + $tree + '\s*(?<br><br>)?\s*$'
$tipOuterPattern = '(?m)^(?<quote>>\s*)?\*\*\s*' + $tree + '\s*(?<label>Tip[^*\r\n<]*?)\s*' + $tree + '\s*\*\*\s*(?<br><br>)?\s*$'
$resourcesInnerPattern = '(?m)^(?<quote>>\s*)?' + $wave + '\s*\*\*(?<label>Resources)\*\*\s*' + $wave + '\s*(?<br><br>)?\s*$'
$resourcesOuterPattern = '(?m)^(?<quote>>\s*)?\*\*\s*' + $wave + '\s*(?<label>Resources)\s*' + $wave + '\s*\*\*\s*(?<br><br>)?\s*$'
$storyInnerPattern = '(?m)^(?<quote>>\s*)?' + $person + '\s*\*\*(?<label>Personal story)\*\*\s*' + $person + '\s*(?<br><br>)?\s*$'
$storyOuterPattern = '(?m)^(?<quote>>\s*)?\*\*\s*' + $person + '\s*(?<label>Personal story)\s*' + $person + '\s*\*\*\s*(?<br><br>)?\s*$'
$ambiguityPattern = '(?m)^(?<quote>>\s*)?<span[^>]*>\s*' + $warning + '\s*(?<label>Ambiguity)\s*' + $warning + '\s*</span>\s*(?<br><br>)?\s*$'

$tipReplacement = '${quote}<span class="callout-label callout-tip"><strong>${label}</strong></span>${br}'
$resourcesReplacement = '${quote}<span class="callout-label callout-resources"><strong>${label}</strong></span>${br}'
$storyReplacement = '${quote}<span class="callout-label callout-story"><strong>${label}</strong></span>${br}'
$ambiguityReplacement = '${quote}<span class="callout-label callout-ambiguity"><strong>${label}</strong></span>${br}'

foreach ($file in $files) {
    if ($file -ieq "README.md") { continue }
    $fullFile = Join-Path $work $file
    $source = Get-Content $fullFile -Raw -Encoding UTF8
    $normalized = $source

    $normalized = [regex]::Replace($normalized, $tipInnerPattern, $tipReplacement)
    $normalized = [regex]::Replace($normalized, $tipOuterPattern, $tipReplacement)
    $normalized = [regex]::Replace($normalized, $resourcesInnerPattern, $resourcesReplacement)
    $normalized = [regex]::Replace($normalized, $resourcesOuterPattern, $resourcesReplacement)
    $normalized = [regex]::Replace($normalized, $storyInnerPattern, $storyReplacement)
    $normalized = [regex]::Replace($normalized, $storyOuterPattern, $storyReplacement)
    $normalized = [regex]::Replace($normalized, $ambiguityPattern, $ambiguityReplacement)

    if ($normalized -ne $source) {
        [System.IO.File]::WriteAllText($fullFile, $normalized, $utf8NoBom)
    }
}

# SUMMARY.md already contains README.md as the Introduction. Replace that entry
# with our cover-free temporary README instead of prepending another README.
$inputs = @()
$summaryHadReadme = $false
foreach ($file in $files) {
    if ($file -ieq "README.md") {
        $summaryHadReadme = $true
        if (Test-Path $kindleReadme) {
            $inputs += $kindleReadme
        } else {
            $inputs += "README.md"
        }
    } else {
        $inputs += $file
    }
}

# Defensive fallback for future upstream SUMMARY changes.
if (-not $summaryHadReadme) {
    if (Test-Path $kindleReadme) {
        $inputs = @($kindleReadme) + $inputs
    } elseif (Test-Path "README.md") {
        $inputs = @("README.md") + $inputs
    }
}
$inputs = $inputs | Select-Object -Unique

if ($inputs.Count -lt 2) {
    throw "Could not determine book chapter order from SUMMARY.md."
}

# Kindle-friendly CSS. Callout colors are deliberately dark and moderately
# saturated so they remain legible on color e-ink; text labels preserve meaning
# on monochrome devices. Ordinary blockquotes are intentionally borderless: the
# source uses them for many consecutive prose paragraphs, and a generic border
# creates a distracting forest of vertical rules on Kindle.
$css = @'
body {
  line-height: 1.45;
}
h1, h2, h3, h4 {
  page-break-after: avoid;
}
pre, code {
  font-family: monospace;
}
pre {
  white-space: pre-wrap;
  overflow-wrap: break-word;
}
img {
  max-width: 100%;
  height: auto;
}

/* Keep quotations visually distinct without drawing a rule beside every
   paragraph. This is especially important in section 1.2.3, where several
   consecutive paragraphs are authored as blockquotes. */
blockquote {
  margin-left: 0.7em;
  margin-right: 0.2em;
  padding-left: 0;
  border: 0;
}

.callout-label {
  font-weight: bold;
  letter-spacing: 0.02em;
}
.callout-tip {
  color: #2f6b3c;
}
.callout-resources {
  color: #2f5f8f;
}
.callout-story {
  color: #6b4f8a;
}
.callout-ambiguity {
  color: #8b3a3a;
}

/* The source occasionally makes an entire sentence an external hyperlink.
   Kindle's default underline then turns the whole sentence into a heavy rule.
   Keep links clickable but use restrained color instead of full underlining. */
a,
a:visited {
  color: #2f5f8f;
  text-decoration: none;
}

/* Kindle-friendly table of contents.
   EPUB3 navigation is structurally an ordered list, but these numbers are not
   the book's chapter numbers. Force list items to ordinary blocks so Kindle
   cannot display misleading 1, 2, 3... markers beside titles that already
   contain their own 1.1 / 2.3 / 5.2 numbering. */
nav#toc {
  margin: 0;
  padding: 0;
}
nav#toc > h1 {
  margin: 0 0 0.8em 0;
  padding-bottom: 0.3em;
  border-bottom: 0.08em solid #777777;
  font-size: 1.8em;
  page-break-before: avoid;
}
nav#toc ol,
nav#toc li {
  display: block;
  list-style: none !important;
  list-style-type: none !important;
  margin: 0;
  padding: 0;
}
nav#toc li::marker {
  content: "" !important;
  font-size: 0;
}
nav#toc a,
nav#toc a:visited {
  display: block;
  color: inherit;
  text-decoration: none;
  line-height: 1.3;
}

/* Level 1: Introduction, Part I, Part II, Appendix. */
nav#toc > ol > li {
  margin-top: 0.9em;
}
nav#toc > ol > li > a {
  color: #2f5f8f;
  font-size: 1.08em;
  font-weight: bold;
}

/* Level 2: chapters and introduction subsections. */
nav#toc > ol > li > ol {
  margin-left: 0.9em;
}
nav#toc > ol > li > ol > li {
  margin-top: 0.45em;
}
nav#toc > ol > li > ol > li > a {
  font-weight: bold;
}

/* Level 3: numbered sections such as 1.1, 2.3, 5.2. */
nav#toc > ol > li > ol > li > ol {
  margin-left: 1em;
}
nav#toc > ol > li > ol > li > ol > li {
  margin-top: 0.28em;
}
nav#toc > ol > li > ol > li > ol > li > a {
  font-weight: normal;
}
'@
$cssPath = Join-Path $work "kindle.css"
[System.IO.File]::WriteAllText($cssPath, $css, $utf8NoBom)

# Wrap bare multiline display equations in an alignment environment so Pandoc's
# MathML converter can handle them reliably.
$mathFilter = @'
function Math(el)
  if el.mathtype == 'DisplayMath'
      and el.text:match('\\\\')
      and not el.text:match('\\begin%s*{') then
    el.text = '\\begin{aligned}\n' .. el.text .. '\n\\end{aligned}'
  end
  return el
end
'@
$mathFilterPath = Join-Path $work "fix-multiline-math.lua"
[System.IO.File]::WriteAllText($mathFilterPath, $mathFilter, $utf8NoBom)

# Include the repo root plus every input file's directory so references such as
# images/image18.png resolve correctly from Markdown files under contents/.
$resourceDirs = @($work)
foreach ($input in $inputs) {
    $fullInput = Join-Path $work $input
    $parent = Split-Path -Parent $fullInput
    if ($parent) { $resourceDirs += $parent }
}
$resourcePath = ($resourceDirs | Select-Object -Unique) -join [IO.Path]::PathSeparator

$outDir = Split-Path -Parent $Output
if ($outDir -and -not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

Write-Host "Building EPUB with Pandoc..."
$args = @(
    "--from=gfm+tex_math_dollars",
    "--to=epub3",
    "--standalone",
    "--toc",
    "--toc-depth=3",
    "--mathml",
    "--lua-filter=$mathFilterPath",
    "--epub-cover-image=$coverPath",
    "--metadata=title:Machine Learning Interviews",
    "--metadata=author:Chip Huyen",
    "--metadata=language:en-US",
    "--metadata=toc-title:Contents",
    "--css=$cssPath",
    "--resource-path=$resourcePath",
    "--output=$Output"
)
$args += $inputs

& pandoc @args
if ($LASTEXITCODE -ne 0) {
    throw "Pandoc failed with exit code $LASTEXITCODE."
}

if (-not (Test-Path $Output)) {
    throw "Pandoc completed but EPUB was not created."
}

Write-Host ""
Write-Host "Done:" -ForegroundColor Green
Write-Host $Output
Write-Host "Cover: contents/images/mlib-cover.png"
Write-Host "TOC: 3 levels, Kindle-safe unnumbered navigation"
Write-Host "Callouts: paired emoji normalized for Kindle"
Write-Host ""
Write-Host "Next: upload the EPUB at https://www.amazon.com/sendtokindle"
