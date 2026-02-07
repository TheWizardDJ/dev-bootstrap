1. Add a new repo to the bootstrap list
- `manifest.json`

2. Change the default workspace or root folder
- `manifest.json`
- `setup-dev.ps1` (path warnings / expectations)
- `dev-sync-start.cmd` (BOOT/MAN assumptions)
- `dev-sync-end.cmd` (BOOT/MAN assumptions)

3. Pin a different Node.js version
- `setup-dev.ps1`

4. Pin a different Codex CLI version
- `setup-dev.ps1`

5. Add or remove a tool install (Git, Python, VS Code, SQLite)
- `setup-dev.ps1`

6. Change auto-discovery exclusions (e.g., skip new folders)
- `update-manifest.ps1`

7. Adjust post-step inference (npm/venv detection)
- `update-manifest.ps1`

8. Change when/how manifest auto-commits and pushes
- `dev-sync-start.cmd`
- `dev-sync-end.cmd`

9. Change repo update behavior (checkout branch, pull strategy)
- `dev-sync-start.cmd`
- `setup-dev.ps1`

10. Modify PATH/`devstart`/`devend` wrapper behavior
- `setup-dev.ps1`

11. Add a repo-specific post step manually (custom path)
- `manifest.json`

12. Change git baseline config (autocrlf, aliases)
- `setup-dev.ps1`
