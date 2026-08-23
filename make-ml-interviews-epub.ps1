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

# README already displays the same cover image at the top. Build a temporary
# Kindle copy without that first image so the EPUB does not show the cover twice.
$kindleReadme = "README-kindle.md"
if (Test-Path "README.md") {
    $readme = Get-Content "README.md" -Raw
    $readme = [regex]::Replace(
        $readme,
        '(?s)^\s*<p\s+align="center">\s*<img[^>]*mlib-cover\.png[^>]*/?>\s*</p>\s*',
        ''
    )
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText((Join-Path $work $kindleReadme), $readme, $utf8NoBom)
}

# Parse Markdown file paths from GitBook/HonKit SUMMARY.md in reading order.
$summary = Get-Content "SUMMARY.md" -Raw
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

# Include the introduction as the opening content page, but without duplicating
# the cover image that Pandoc will embed as the EPUB's formal cover.
$inputs = @()
if (Test-Path $kindleReadme) {
    $inputs += $kindleReadme
} elseif (Test-Path "README.md") {
    $inputs += "README.md"
}
$inputs += $files | Select-Object -Unique

if ($inputs.Count -lt 2) {
    throw "Could not determine book chapter order from SUMMARY.md."
}

# Kindle-friendly CSS: intentionally conservative so Kindle can reflow cleanly.
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
blockquote {
  margin-left: 1em;
  margin-right: 0;
}
'@
$cssPath = Join-Path $work "kindle.css"
Set-Content -Path $cssPath -Value $css -Encoding UTF8

# Pandoc's MathML conversion handles ordinary LaTeX well, but display equations
# that use bare \\ line breaks need an alignment environment. This filter wraps
# only those display-math blocks that are not already inside a LaTeX environment.
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
if (-not $utf8NoBom) {
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
}
[System.IO.File]::WriteAllText($mathFilterPath, $mathFilter, $utf8NoBom)

# Pandoc resolves image paths relative to its working directory, while this book
# contains references such as images/image18.png from Markdown files under
# contents/. Include the root plus every input file's directory in resource-path.
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
Write-Host ""
Write-Host "Next: upload the EPUB at https://www.amazon.com/sendtokindle"
