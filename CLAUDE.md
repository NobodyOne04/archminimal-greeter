# archminimal-greeter

The Arch login screen: greetd + a Quickshell greeter inside a greeter-only Hyprland, in the archminimal look.
Formerly `sddm-login` (it never used SDDM). Installed system-wide on the Arch VM; the desktop's lock screen
(`~/projects/hyprland`, `quickshell/LockScreen.qml`) copies this look. Install, config keys, troubleshooting:
`README.md`.

## Commands
- `make lint`: config JSON, shellcheck, `Hyprland --verify-config` on `system/hyprland.lua` (must say
  `config ok`), qmllint (informational: mostly false "not found on type" warnings for Quickshell singletons).
  CI runs it in an Arch container as a non-root user on every PR. Not runnable on macOS.
- `make preview`: the greeter in a window, no login, no power actions (Arch desktop session only).
- On Arch, as root: `make install` (files only), `make enable` / `revert` (switch display managers),
  `make status`, `make logs`, `make diagnose` (as the user, from a TTY, after a failed login).

## Layout
- `system/archminimal-greeter`: launcher greetd runs as user `greeter`; starts Hyprland, falls back to
  `agreety` (text login) when anything is missing or Hyprland exits non-zero.
- `system/hyprland.lua`: greeter-only Hyprland (no binds, no apps); starts `qs`, exits after login.
  `/etc/archminimal-greeter/local.lua` (machine tweaks) is loaded last.
- `system/display-manager.sh`: enable / revert / status, records the replaced display manager.
- `greeter/`: `shell.qml` entry, `Greeter.qml` screen + greetd flow, `Sessions.qml` session command,
  `LoginState.qml` last user/session, `Config.qml` reads `/etc/archminimal-greeter/config.json`.

## Conventions
- **Security is the point of this repo.** The password goes only to a hidden PAM prompt, is cleared after use
  and is never logged; quickshell's greetd debug log stays off (`--log-rules` in `hyprland.lua`, it logs the
  reply). State and logs are private (0700 dir, umask 077, session log 600). The greeter gets no keybinds or
  ways to start programs: anything added there runs as `greeter` before anyone has logged in.
- The session command is ONE shell string (greetd runs `sh -c "…; exec <cmd>"`): build it with `shq()`;
  never splice user or .desktop text in unquoted.
- Never leave a path where a broken install means no way to log in: keep the `agreety` fallback working,
  and test launcher changes with stub commands (fake `start-hyprland` exiting 0 / non-zero).
- Installed paths are all named `archminimal-greeter`; changing one means a migration in `make install`.
- Changes go through `github-flow` (squash only). Anything in the login flow needs a real login on the VM
  before merging: CI only proves the files parse.
