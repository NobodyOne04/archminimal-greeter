# Changelog

## Unreleased

### Added
- Decision records in `docs/adr/`: eight ADRs for the repo's existing decisions
- Copied from `NobodyOne04/sddm-login` at `b58cb01` under a name that matches what it is: a greetd + Quickshell greeter (no SDDM)
- CI runs `make lint` on every PR, in an Arch container; `make lint` now also runs `Hyprland --verify-config`
  on the greeter's own `system/hyprland.lua`
- `CLAUDE.md`: how to work on this repo with Claude Code

### Changed
- Sibling repos renamed: links and paths say `archminimal-setup` (was `linux_setup`) and `archminimal-hypr`
  (was `hyprland`), incl. the hint in `make diagnose`

### Fixed
- Safety net: when Hyprland is installed but can't run (no 3D in a VM, a crash after an update), the launcher
  now falls back to the text login instead of greetd restarting a broken greeter in a loop
- The password only answers a hidden PAM prompt; a visible one (username, a code asked first) gets
  "unsupported prompt" instead of the password typed into it
- The session log (`~/.local/state/archminimal-session.log`) is readable by its user only
- `make lint` never ran qmllint on Arch (it lives in `/usr/lib/qt6/bin`, not on PATH)
- README after the rename: paths, file list (`LoginState.qml`, `diagnose.sh`), what the safety net covers
