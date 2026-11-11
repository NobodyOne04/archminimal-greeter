#!/bin/sh
# ls -t is used on Hyprland instance dirs and crash reports, whose names are alphanumeric.
# shellcheck disable=SC2012
# Collect everything about the last login attempt. Run as your normal user
# from a text console (Ctrl+Alt+F2) after a login that did not reach the
# desktop, then send the output.
here=$(cd "$(dirname "$0")" && pwd)

section() { printf '\n===== %s =====\n' "$1"; }

section "login screen"
sh "$here/display-manager.sh" status
if grep -q start-hyprland /usr/local/bin/archminimal-greeter 2>/dev/null; then
    echo "  launcher:        up to date"
else
    echo "  launcher:        OUTDATED or missing (git pull && sudo make install)"
fi

section "greeter log (/var/cache/archminimal-greeter/greeter.log)"
# private to the greeter user (0700), so read it with sudo
{ sudo cat /var/cache/archminimal-greeter/greeter.log 2>/dev/null || echo "(none yet)"; } | grep -vE "^[[:space:]]*$" | tail -n 30

section "greetd log (this boot)"
journalctl -b -u greetd --no-pager 2>/dev/null | tail -n 25 ||
    echo "(no access: run 'sudo journalctl -b -u greetd | tail -25')"

section "session log (~/.local/state/archminimal-session.log)"
if [ -f "$HOME/.local/state/archminimal-session.log" ]; then
    tail -n 40 "$HOME/.local/state/archminimal-session.log"
else
    echo "(none: no login since this version was installed, or the session never started)"
fi

section "Hyprland log (latest instance)"
latest=$(ls -td "${XDG_RUNTIME_DIR:-/run/user/$(id -u)}"/hypr/*/ 2>/dev/null | head -n 1)
if [ -n "$latest" ] && [ -f "$latest/hyprland.log" ]; then
    grep -iE "err|crit|fail|warn|exit|abort" "$latest/hyprland.log" | tail -n 25
else
    echo "(no Hyprland log in this login's runtime dir)"
fi

section "crash report (latest)"
crash=$(ls -t "$HOME"/.cache/hyprland/hyprlandCrashReport*.txt 2>/dev/null | head -n 1)
if [ -n "$crash" ]; then echo "$crash"; head -n 30 "$crash"; else echo "(none)"; fi

section "desktop config"
ls -la "$HOME/.config/hypr/" 2>&1 | tail -n +2
if [ -f "$HOME/.config/hypr/hyprland.lua" ]; then
    Hyprland --verify-config --config "$HOME/.config/hypr/hyprland.lua" 2>&1 | sed -n '/parsing result/,$p'
else
    echo "(no ~/.config/hypr/hyprland.lua: desktop repo not installed? cd ~/projects/archminimal-hypr && make install)"
fi
for c in start-hyprland Hyprland qs kitty hypridle; do
    printf '  %-15s %s\n' "$c" "$(command -v "$c" || echo MISSING)"
done
