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
git clone --depth 1 https://github.com/chiphuyen/ml-interviews-book.git $work

Set-Location $work

if (-not (Test-Path "SUMMARY.md")) {
    throw "SUMMARY.md not found."
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

# Include README as the opening page if SUMMARY doesn't already point to it.
$inputs = @()
if (Test-Path "README.md") { $inputs += "README.md" }
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
    "--metadata=title:Machine Learning Interviews",
    "--metadata=author:Chip Huyen",
    "--metadata=language:en-US",
    "--css=$cssPath",
    "--resource-path=$work",
    "--output=$Output"
)
$args += $inputs

& pandoc @args

if (-not (Test-Path $Output)) {
    throw "Pandoc completed but EPUB was not created."
}

Write-Host ""
Write-Host "Done:" -ForegroundColor Green
Write-Host $Output
Write-Host ""
Write-Host "Next: upload the EPUB at https://www.amazon.com/sendtokindle"
