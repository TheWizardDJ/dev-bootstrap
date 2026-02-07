`setup-dev.ps1`
- Owns: Full machine/bootstrap setup, tool installs, PATH, repo clone/pull, version pinning.
- Must not: Assume non-Windows shells; modify repos beyond clone/pull and optional post steps.
- Depends on: `manifest.json`, `dev-sync-start.cmd`, `dev-sync-end.cmd`.

`update-manifest.ps1`
- Owns: Discovering git repos and rewriting `manifest.json` deterministically.
- Must not: Install tools or alter repo state beyond reading `origin` URL.
- Depends on: `manifest.json`.

`dev-sync-start.cmd`
- Owns: Start-of-session sync (pull bootstrap, update manifest, clone/pull repos).
- Must not: Force-push or modify repo content besides git fetch/checkout/pull.
- Depends on: `update-manifest.ps1`, `manifest.json`, git CLI.

`dev-sync-end.cmd`
- Owns: End-of-session sync (update manifest, push clean repos).
- Must not: Commit/push dirty repos; should warn instead.
- Depends on: `update-manifest.ps1`, `manifest.json`, git CLI.

`manifest.json`
- Owns: Workspace/root config and repo list (+ optional post steps).
- Must not: Contain machine-specific secrets.
- Depends on: Read by `setup-dev.ps1`, `update-manifest.ps1`, `dev-sync-start.cmd`, `dev-sync-end.cmd`.
