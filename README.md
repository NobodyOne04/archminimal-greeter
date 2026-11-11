# archminimal login screen

A minimal Arch login screen built with **Quickshell** and **greetd**: one cyan accent, corner marks, a brief logo
glitch, faint scanlines and a blinking `sys::ready` cursor. **No SDDM**: nothing here uses or installs it.

```text
greetd  (tiny login daemon, root)
  └─ archminimal-greeter  (as user "greeter")
       └─ start-hyprland -- --config /usr/share/archminimal-greeter/hyprland.lua   (greeter-only Hyprland)
            └─ qs -p /usr/share/archminimal-greeter                 (Quickshell QML greeter)
                 └─ on success → greetd starts your session (e.g. Hyprland)
```

- **greetd** handles PAM and starting sessions: a few hundred KB, no Qt, no X server.
- **Quickshell** draws the screen in QML.
- **Hyprland** is only the compositor for the login screen, with its own minimal config; your `~/.config/hypr`
  is not touched.
- **Safety net:** if Hyprland, Quickshell or the greeter files are missing, or Hyprland exits with an error
  (no 3D in a VM, a crash after an update), the launcher falls back to `agreety`, greetd's text login, so a
  broken install never locks you out.

> This repository was called `sddm-login` until November 2026; it never contained SDDM code.

## 1. Install

As part of the whole setup, [`linux_setup`](https://github.com/NobodyOne04/linux_setup)'s `make all` does all of
this. On its own:

```bash
make deps           # greetd, hyprland, quickshell, qt6-svg, JetBrains Mono (official repos)
make check          # commands, font, greeter user, Wayland sessions
make preview        # optional: try it in a window from your desktop (no login, Esc quits)
sudo make install   # copy files; the login manager is not changed yet
sudo make enable    # greetd becomes the login screen from the next boot
reboot
```

`make enable` takes over from **whatever display manager is active**: SDDM (archinstall's Hyprland and KDE
profiles install it), GDM, LightDM, ly, or none. It disables that one, records it, and enables greetd.

Don't want SDDM on the machine at all? After `make enable`:

```bash
sudo make remove-sddm   # uninstalls the sddm package (only allowed once greetd is active)
```

Undo:

```bash
sudo make revert   # greetd off; the recorded display manager back on (or a text login if there was none)
```

What `install` puts where:

| Path | Contents |
|---|---|
| `/usr/share/archminimal-greeter/` | QML, session lister, wallpaper, greeter-only `hyprland.lua` (all replaced on every install) |
| `/usr/local/bin/archminimal-greeter` | launcher started by greetd |
| `/etc/archminimal-greeter/config.json` | **your settings** (never overwritten by `make install`) |
| `/etc/archminimal-greeter/local.lua` | **your** Hyprland tweaks for the login screen (optional; never touched) |
| `/var/cache/archminimal-greeter/` | last user and session, caches (owned by `greeter`) |
| `/etc/greetd/config.toml` | written by `make enable`; the previous one is kept as `config.toml.pre-archminimal-greeter` |

## 2. Customize

Edit `/etc/archminimal-greeter/config.json` with `sudo`; it applies the next time the greeter starts. To try
changes first, edit `config/config.json` here and run `make preview`.

| Key | Default | What it does |
|---|---|---|
| `background` | `background.png` | Wallpaper; an absolute path, or relative to `/usr/share/archminimal-greeter` |
| `bgColor` | `#28292d` | Fallback color behind the wallpaper |
| `fg` / `mute` | `#d0d2d0` / `#7d8088` | Main and dim text colors |
| `accent` | `#00e5ff` | The cyan touch (try `#ff2a6d` or `#b026ff`) |
| `danger` | `#ff2a6d` | Error and shutdown hover color |
| `fontFamily` | `JetBrains Mono` | Any installed monospace font |
| `headerText` | `ARCH//LINUX` | Top-left label |
| `rememberUser` | `true` | Pre-fill the last user who logged in |
| `defaultUser` | `""` | User to pre-fill when nobody is remembered |
| `showSession` | `false` | Show the session name bottom-left; click it to cycle |
| `defaultSession` | `hyprland` | Session id (file name in `/usr/share/wayland-sessions` without `.desktop`) |
| `showPower` | `true` | Reboot and shutdown buttons |
| `glitch` | `true` | Logo flicker every ~2.5 seconds |
| `scanlines` | `true` | Very faint scanlines |
| `loginY` | `0.70` | Vertical position of the login block (fraction of screen height) |
| `primaryScreen` | `""` | Output that shows the form (e.g. `DP-1`); default is the first one |

Keyboard layout and monitor modes for the login screen go in `/etc/archminimal-greeter/local.lua` (Hyprland 0.57+
Lua format), for example:

```lua
hl.config({ input = { kb_layout = "us,ru", kb_options = "grp:alt_shift_toggle" } })
hl.monitor({ output = "DP-1", mode = "2560x1440@144", position = "0x0", scale = 1 })
```

**Updating:** `git pull && sudo make install`. It ends with `✓ installed: …` when the new launcher is in place;
`make status` shows `launcher: up to date` or `OUTDATED`.

## 3. Behaviour

- `Enter` in the user field moves to the password; `Enter` in the password field (or `→`) logs in.
- A wrong password shows `authentication failed` with a short shake; while checking it reads `auth::pending`.
- Only **Wayland** sessions are offered (from `/usr/share/wayland-sessions`).
- Password logins are supported; PAM setups that ask a second question (e.g. a one-time code) show
  `unsupported prompt`.
- Reboot and shutdown use `systemctl`, which logind allows for the active local login screen.

## 4. Troubleshooting

**You log in, but end up back at the login screen.** The desktop session started and died. Every session's
output is saved to `~/.local/state/archminimal-session.log`. From `Ctrl+Alt+F2`, run
`make -C ~/projects/archminimal-greeter diagnose`: it collects the greetd log, that session log, Hyprland's log and crash
report, and checks your desktop config.

**Black screen or the greeter keeps restarting.** `Ctrl+Alt+F2`, log in, then:

```bash
cd ~/projects/archminimal-greeter
make status            # which display manager is active
make logs              # greetd log of this boot
sudo make revert       # back to the previous display manager (or a text login)
```

The greeter's own logs while it is failing:

```bash
sudo sh -c 'tail -n 50 /run/user/$(id -u greeter)/hypr/*/hyprland.log'
```

**In a virtual machine** Hyprland needs 3D acceleration (virtio-gpu with GL in QEMU/virt-manager, or 3D
enabled in VMware/VirtualBox). Without it, the greeter cannot start and the safety net shows a text login.

**Plain text login instead of the theme.** The safety net kicked in: Hyprland, Quickshell or the greeter
files are missing (`make check` shows which), or Hyprland could not run (no 3D in a VM, a crash after an
update; `sudo journalctl -b -u greetd` has the exit status).

## Makefile

| Target | What |
|---|---|
| `make deps` / `check` / `lint` | install packages / verify them / static checks, incl. `Hyprland --verify-config` (CI runs `lint` on every PR) |
| `make preview` | run the greeter in a window |
| `sudo make install` / `uninstall` | install or remove files |
| `sudo make enable` / `revert` | make greetd the login screen / undo |
| `sudo make remove-sddm` | uninstall SDDM after `enable` |
| `make status` / `logs` | active display manager, last login / greetd journal |
| `make diagnose` | after a login that didn't reach the desktop: collect every relevant log |

## Files

```text
greeter/
  shell.qml          entry point: one overlay per monitor, or a window in preview
  Greeter.qml        the screen + greetd login flow
  Config.qml         reads config.json
  LoginState.qml     remembers last user and session
  Sessions.qml       Wayland sessions, launch command and environment
  list-sessions.sh   parses /usr/share/wayland-sessions/*.desktop
  background.png
config/config.json   default settings
system/
  archminimal-greeter   launcher (with agreety fallback)
  hyprland.lua          greeter-only Hyprland config
  greetd.toml           /etc/greetd/config.toml
  display-manager.sh    hands the login screen to greetd and back
  diagnose.sh           `make diagnose`: every log about the last login
  tmpfiles.conf         creates /var/cache/archminimal-greeter
```
