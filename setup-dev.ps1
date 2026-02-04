# setup-dev.ps1
# Run in PowerShell (Admin recommended for winget installs).
$ErrorActionPreference = "Stop"

function Write-Section($msg) { Write-Host "`n==== $msg ====" -ForegroundColor Cyan }
function Have-Cmd($name) { return [bool](Get-Command $name -ErrorAction SilentlyContinue) }
function Run([string]$Exe, [string[]]$ArgList) {
  if ($null -eq $ArgList -or $ArgList.Count -eq 0) {
    throw "Refusing to run '$Exe' with no arguments (script bug)."
  }

  & $Exe @ArgList
  if ($LASTEXITCODE -ne 0) {
    throw "Failed: $Exe $($ArgList -join ' ')"
  }
}
function Ensure-Folder($path) { if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null } }

# Read manifest
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$manifestPath = Join-Path $here "manifest.json"
if (!(Test-Path $manifestPath)) { throw "Missing manifest.json at $manifestPath" }
$cfg = Get-Content $manifestPath -Raw | ConvertFrom-Json

$Root = $cfg.root
$Workspace = $cfg.workspace

Write-Section "Folders"
Ensure-Folder $Root
Ensure-Folder $Workspace

Write-Section "Install core tools (winget)"
if (!(Have-Cmd "winget")) {
  throw "winget not found. Install App Installer or tell me and I'll give you a Chocolatey version."
}

# Core dev tools
& winget install --id Git.Git --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
& winget install --id OpenJS.NodeJS --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
& winget install --id Python.Python.3.13 --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host
& winget install --id Microsoft.VisualStudioCode --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host

# SQLite (best-effort; ids vary by machine)
try { & winget install --id SQLite.SQLite --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host } catch {}
try { & winget install --id DBBrowserForSQLite.DBBrowserForSQLite --exact --silent --accept-package-agreements --accept-source-agreements | Out-Host } catch {}

# Refresh PATH in current session
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

Write-Section "Git baseline config"
Run "git" @("config","--global","credential.useHttpPath","true")
Run "git" @("config","--global","core.autocrlf","true")
Run "git" @("config","--global","alias.s","status")

Write-Section "Clone/Pull repos from manifest"
foreach ($r in $cfg.repos) {
  $repoPath = Join-Path $Workspace $r.name

  if (!(Test-Path $repoPath)) {
    Write-Host "Cloning $($r.name) -> $repoPath"
    Run "git" @("clone",$r.url,$repoPath)
  } else {
    Write-Host "Updating $($r.name) in $repoPath"
    Push-Location $repoPath
    try {
      Run "git" @("fetch","--all","--prune")
      Run "git" @("checkout","main")
      Run "git" @("pull")
    } finally { Pop-Location }
  }

  # Post steps
  if ($r.post) {
    foreach ($p in $r.post) {
      $stepDir = Join-Path $repoPath $p.path
      if (!(Test-Path $stepDir)) {
        Write-Host "Skip post step (missing path): $stepDir"
        continue
      }

      switch ($p.type) {
        "npm" {
          Write-Section "npm: $($r.name)\$($p.path)"
          Push-Location $stepDir
          try {
            & npm install | Out-Host
          } finally { Pop-Location }
        }
        "python_venv" {
          Write-Section "python venv: $($r.name)\$($p.path)"
          Push-Location $stepDir
          try {
            $venv = Join-Path $stepDir ".venv"
            if (!(Test-Path $venv)) { Run "py" @("-m","venv",".venv") }
            $pip = Join-Path $venv "Scripts\pip.exe"
            & $pip install --upgrade pip setuptools wheel | Out-Host
            $req = Join-Path $stepDir $p.requirements
            if (Test-Path $req) { & $pip install -r $p.requirements | Out-Host }
          } finally { Pop-Location }
        }
        default {
          Write-Host "Unknown post type: $($p.type) (skipping)"
        }
      }
    }
  }
}

Write-Section "Codex CLI (npm global)"
# If your codex package name differs, change it here:
& npm install -g codex | Out-Host

Write-Section "Verify"
& git --version | Out-Host
& node -v | Out-Host
& npm -v | Out-Host
& python --version | Out-Host

Write-Host "`nDONE. Workspace: $Workspace" -ForegroundColor Green
