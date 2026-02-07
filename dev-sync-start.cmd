@echo off
setlocal
set BOOT=C:\Codex\popz-workspace\dev-bootstrap
set MAN=%BOOT%\manifest.json

REM 1) Update dev-bootstrap itself so manifest/scripts are current
cd /d %BOOT%
git pull

REM 2) Refresh manifest by auto-discovery (safe)
powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOT%\update-manifest.ps1"

REM 3) If manifest changed, commit+push it (so other machine sees new repos)
cd /d %BOOT%
git status --porcelain >nul
for /f %%A in ('git status --porcelain') do set DIRTY=1
if defined DIRTY (
  git add -A
  git commit -m "chore: auto-update manifest"
  git push
  set DIRTY=
)

REM 4) Clone missing repos, then pull all
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$cfg=Get-Content '%MAN%' -Raw | ConvertFrom-Json; " ^
  "$ws=$cfg.workspace; " ^
  "foreach($r in $cfg.repos){ " ^
  " $p = if($r.path){ $r.path } else { Join-Path $ws $r.name }; " ^
  " Write-Host ('-- ' + $p); " ^
  " if(!(Test-Path $p)){ " ^
  "   Write-Host 'CLONE -> ' $r.url; " ^
  "   git clone $r.url $p; " ^
  " } " ^
  " Push-Location $p; " ^
  " git status; git fetch --all --prune; git checkout main; git pull; " ^
  " Pop-Location; Write-Host '' }"
