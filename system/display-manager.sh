#!/bin/sh
# Hand the login screen over to greetd (enable), give it back (revert), or
# show who owns it (status).
#
# Display managers register in one of two ways:
#   - as /etc/systemd/system/display-manager.service (sddm, gdm, lightdm, ...)
#   - as a unit wanted by a target, without that alias (ly@ttyN, emptty, ...)
# `enable` disables every display manager it finds either way, records them,
# and enables greetd. `revert` disables greetd and re-enables only what was
# recorded; if nothing was, the machine boots to a text login, never to SDDM.
set -eu

LINK=/etc/systemd/system/display-manager.service
RECORD=${RECORD:-/etc/archminimal-greeter/previous-display-manager}
KNOWN='^(sddm|gdm|lightdm|lxdm|xdm|slim|emptty|lemurs|ly|ly@.+|ly-kmsconvt@.+)\.service$'

alias_owner() {
    t=$(readlink "$LINK" 2>/dev/null || true)
    if [ -n "$t" ]; then basename "$t"; fi
}

# every enabled display manager other than greetd, one per line
other_dms() {
    {
        alias_owner
        for f in /etc/systemd/system/*.wants/*.service; do
            [ -L "$f" ] && basename "$f"
        done
    } | grep -E "$KNOWN" | sort -u || true
}

case ${1:-status} in
enable)
    others=$(other_dms)
    if [ -n "$others" ]; then
        mkdir -p "$(dirname "$RECORD")"
        printf '%s\n' "$others" > "$RECORD"
        for u in $others; do
            systemctl disable "$u"
            echo "disabled $u (recorded for 'make revert')"
        done
    fi
    systemctl enable greetd.service
    if [ "$(alias_owner)" != greetd.service ]; then
        echo "error: greetd is not the display manager after enabling; check: ls -l $LINK" >&2
        exit 1
    fi
    echo "greetd is the login screen from the next boot"
    ;;
revert)
    systemctl disable greetd.service 2>/dev/null || true
    if [ -s "$RECORD" ]; then
        while IFS= read -r u; do
            [ -n "$u" ] || continue
            if systemctl cat "$u" >/dev/null 2>&1; then
                systemctl enable "$u"
                echo "re-enabled $u"
            else
                echo "$u was recorded but is no longer installed"
            fi
        done < "$RECORD"
        rm -f "$RECORD"
    fi
    if [ -z "$(other_dms)" ]; then
        echo "no display manager enabled: the next boot shows a text login (TTY)"
    fi
    ;;
status)
    cur=$(alias_owner)
    echo "  display manager: ${cur:-none}"
    extra=$(other_dms | grep -vx "${cur:-none}" || true)
    if [ -n "$extra" ]; then echo "  also enabled:    $(echo "$extra" | tr '\n' ' ')"; fi
    if [ -s "$RECORD" ]; then echo "  replaced:        $(tr '\n' ' ' < "$RECORD")(restored by 'make revert')"; fi
    ;;
*)
    echo "usage: $0 enable|revert|status" >&2
    exit 2
    ;;
esac
