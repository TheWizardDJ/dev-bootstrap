# REPO_MAP

Purpose
- Windows bootstrap for a multi-repo Codex dev workspace; keeps repos in sync and installs required tools.
- Provides `devstart`/`devend` wrappers to update/push repos and keep `manifest.json` current.

Runtime/Hosting Hints
- Windows PowerShell scripts and `.cmd` batch wrappers.
- Uses `winget`, `git`, `node`, `npm`, and `py` (Python) on local machine.
- Intended layout: `C:\Codex\dev-bootstrap` and workspace under `C:\Codex\popz-workspace`.

High-Level Architecture
- `setup-dev.ps1`: full bootstrap (folders, tool installs, PATH, CLI pinning).
- `update-manifest.ps1`: discovers git repos and rewrites `manifest.json`.
- `dev-sync-start.cmd`: pulls dev-bootstrap, updates manifest, commits/pushes manifest, clones/pulls all repos.
- `dev-sync-end.cmd`: updates manifest, commits/pushes manifest, pushes clean repos.
- `manifest.json`: source of truth for root/workspace and repo list (+ optional post steps).

Primary Entry Points
- `setup-dev.ps1`
- `dev-sync-start.cmd` (invoked by `devstart` wrapper in `C:\Codex\bin`)
- `dev-sync-end.cmd` (invoked by `devend` wrapper in `C:\Codex\bin`)

Core Logic Files
- `setup-dev.ps1`
- `update-manifest.ps1`
- `dev-sync-start.cmd`
- `dev-sync-end.cmd`

Config/Flags Locations
- `manifest.json`: `root`, `workspace`, `repos` list, optional `post` steps.
- `setup-dev.ps1`: `$NodeVersion`, `$CodexVersion`, install list, PATH handling, bootstrap paths.
- `update-manifest.ps1`: `$exclude` regex, repo discovery, post-step inference rules.
- `dev-sync-start.cmd` / `dev-sync-end.cmd`: `BOOT`, `MAN`, git checkout/pull/push behavior.

Dangerous Areas
- `setup-dev.ps1`: installs tools via `winget`, modifies PATH, writes to `C:\Codex\bin`.
- `dev-sync-start.cmd`: auto-commits and pushes `manifest.json`.
- `dev-sync-end.cmd`: auto-pushes clean repos; warns on dirty worktrees.
- `update-manifest.ps1`: auto-discovers repos and rewrites `manifest.json` (can drop entries without `origin`).
