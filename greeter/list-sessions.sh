#!/bin/sh
# Prints one line per visible Wayland session:
#   id <TAB> name <TAB> DesktopNames <TAB> Exec
for dir in /usr/share/wayland-sessions /usr/local/share/wayland-sessions; do
    [ -d "$dir" ] || continue
    for f in "$dir"/*.desktop; do
        [ -f "$f" ] || continue
        awk -v id="$(basename "$f" .desktop)" '
            /^\[/ { section = $0; next }
            section != "[Desktop Entry]" { next }
            /^Name=/ && name == "" { name = substr($0, 6) }
            /^Exec=/ { cmd = substr($0, 6) }
            /^DesktopNames=/ { dn = substr($0, 14) }
            /^(Hidden|NoDisplay)=true/ { hidden = 1 }
            END { if (!hidden && cmd != "") printf "%s\t%s\t%s\t%s\n", id, name, dn, cmd }
        ' "$f"
    done
done
