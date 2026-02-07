Purpose: Windows bootstrap for a multi-repo Codex dev workspace; keeps repos in sync and installs required tools.
Purpose: Provides `devstart`/`devend` wrappers to update/push repos and keep `manifest.json` current.

Runtime/Hosting Hints
- Windows PowerShell scripts and `.cmd` batch wrappers.
- Uses `winget`, `git`, `node`, `npm`, and `py` (Python) on local machine.
- Intended location: `C:\Codex\dev-bootstrap` with workspace under `C:\Codex\popz-workspace`.

High-Level Architecture
- `setup-dev.ps1`: Full bootstrap (folders, tool installs, repo clone/pull, PATH, CLI pinning).
- `update-manifest.ps1`: Discovers git repos and rewrites `manifest.json`.
- `dev-sync-start.cmd`: Pulls dev-bootstrap, updates manifest, commits/pushes manifest, clones/pulls all repos.
- `dev-sync-end.cmd`: Updates manifest, commits/pushes manifest, pushes clean repos.
- `manifest.json`: Source of truth for root/workspace and repo list (+ optional post steps).

Primary Entry Points
- `setup-dev.ps1`
- `dev-sync-start.cmd` (invoked by `devstart` wrapper)
- `dev-sync-end.cmd` (invoked by `devend` wrapper)

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
- `setup-dev.ps1`: Installs/uninstalls tools via `winget`, modifies PATH, writes to `C:\Codex\bin`.
- `dev-sync-start.cmd`: Auto-commits and pushes `manifest.json`.
- `dev-sync-end.cmd`: Auto-pushes clean repos; warns on dirty worktrees.
- `update-manifest.ps1`: Auto-discovers repos and rewrites `manifest.json` (can drop entries without `origin`).
