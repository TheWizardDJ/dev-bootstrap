@echo off
setlocal
set BOOT=C:\Codex\popz-workspace\dev-bootstrap
set MAN=%BOOT%\manifest.json

REM 1) Refresh manifest by auto-discovery
powershell -NoProfile -ExecutionPolicy Bypass -File "%BOOT%\update-manifest.ps1"

REM 2) Commit/push manifest changes so other machine will clone new repos
cd /d %BOOT%
git fetch --all --prune
git pull --ff-only
for /f %%A in ('git status --porcelain') do set DIRTY=1
if defined DIRTY (
  git add -A
  git commit -m "chore: auto-update manifest"
  git push
  set DIRTY=
)

REM 3) Push all clean repos
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$cfg=Get-Content '%MAN%' -Raw | ConvertFrom-Json; " ^
  "$ws=$cfg.workspace; " ^
  "foreach($r in $cfg.repos){ " ^
  " $p = if($r.path){ $r.path } else { Join-Path $ws $r.name }; " ^
  " Write-Host ('-- ' + $p); " ^
  " if(!(Test-Path $p)){ Write-Host 'MISSING REPO FOLDER'; continue } " ^
  " Push-Location $p; " ^
  " git status; " ^
  " $dirty = (git status --porcelain); " ^
  " if($dirty){ Write-Host 'WARNING: DIRTY WORKTREE (commit before switching machines)'; } else { git push; } " ^
  " Pop-Location; Write-Host '' }"
