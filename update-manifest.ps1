# Auto-discover git repos under C:\Codex and keep manifest.json updated.
$ErrorActionPreference = "Stop"

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $here "manifest.json"
$cfg = Get-Content $manifestPath -Raw | ConvertFrom-Json

$root = $cfg.root
$workspace = $cfg.workspace

$exclude = '\\(\.git|node_modules|\.venv|dist|build|\.next|__pycache__)\\'

function Get-RepoOriginUrl($repoPath) {
  Push-Location $repoPath
  try {
    $url = (git remote get-url origin 2>$null).Trim()
    if ([string]::IsNullOrWhiteSpace($url)) { return $null }
    return $url
  } finally { Pop-Location }
}

function Infer-PostSteps($repoPath) {
  $steps = @()

  # Node backend in /backend
  if (Test-Path (Join-Path $repoPath "backend\package.json")) {
    $steps += [pscustomobject]@{ type="npm"; path="backend"; command="npm install" }
  } elseif (Test-Path (Join-Path $repoPath "package.json")) {
    $steps += [pscustomobject]@{ type="npm"; path="."; command="npm install" }
  }

  # Python bot style
  if (Test-Path (Join-Path $repoPath "requirements.txt")) {
    $steps += [pscustomobject]@{ type="python_venv"; path="."; requirements="requirements.txt" }
  }

  return $steps
}

# Find top-level git repos under root (common case)
$top = Get-ChildItem $root -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { Test-Path (Join-Path $_.FullName ".git") }

# Also find nested repos (in case you put them under other folders)
$nestedGitDirs = Get-ChildItem $root -Recurse -Directory -Force -ErrorAction SilentlyContinue |
  Where-Object { $_.Name -eq ".git" -and $_.FullName -notmatch $exclude }

$repos = @()

foreach ($d in $top) {
  $repos += $d.FullName
}

foreach ($g in $nestedGitDirs) {
  $repoPath = Split-Path -Parent $g.FullName
  if ($repoPath -notin $repos) { $repos += $repoPath }
}

# Build new repo entries
$newEntries = @()
foreach ($repoPath in ($repos | Sort-Object -Unique)) {
  if ($repoPath -match $exclude) { continue }

  $url = Get-RepoOriginUrl $repoPath
  if ($null -eq $url) { continue } # no origin -> skip

  $name = Split-Path -Leaf $repoPath
  $entry = [ordered]@{
    name = $name
    url  = $url
  }

  # Only include path if it's NOT the default workspace\name
  $defaultPath = Join-Path $workspace $name
  if ($repoPath -ne $defaultPath) {
    $entry.path = $repoPath.Replace("\","\\")
  }

  $post = Infer-PostSteps $repoPath
  if ($post.Count -gt 0) { $entry.post = $post }

  $newEntries += [pscustomobject]$entry
}

# Replace cfg.repos with sorted list
$cfg.repos = $newEntries | Sort-Object name

# Write back JSON (pretty)
$json = $cfg | ConvertTo-Json -Depth 10
Set-Content -Path $manifestPath -Value $json -Encoding UTF8

Write-Host "Manifest updated with $($cfg.repos.Count) repos." -ForegroundColor Green
