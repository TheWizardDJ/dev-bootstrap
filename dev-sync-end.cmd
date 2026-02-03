@echo off
setlocal
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$cfg=Get-Content '%~dp0manifest.json' -Raw | ConvertFrom-Json; " ^
  "$ws=$cfg.workspace; " ^
  "foreach($r in $cfg.repos){ " ^
  " $p=Join-Path $ws $r.name; " ^
  " Write-Host ('-- ' + $p); " ^
  " if(!(Test-Path $p)){ Write-Host 'MISSING REPO FOLDER'; continue } " ^
  " Push-Location $p; " ^
  " git status; " ^
  " $dirty = (git status --porcelain); " ^
  " if($dirty){ Write-Host 'WARNING: DIRTY WORKTREE (commit before switching machines)'; } else { git push; } " ^
  " Pop-Location; Write-Host '' }"
