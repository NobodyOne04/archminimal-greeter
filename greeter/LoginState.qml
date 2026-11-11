// Remembers the last user and session between logins.
// (Not called "State": that name is taken by QtQuick's built-in State type,
// which silently shadowed this singleton and broke the login.) Stored in a directory
// writable by the greeter user (created by systemd-tmpfiles at install).
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: state

    readonly property string dir: Quickshell.env("ARCHMINIMAL_STATE_DIR") || "/var/cache/archminimal-greeter"
    property string lastUser: ""
    property string lastSession: ""

    FileView {
        id: file
        path: state.dir + "/state.json"
        blockLoading: true
        printErrors: false   // no state yet on the very first login
    }

    Component.onCompleted: {
        const text = file.text()
        if (!text)
            return
        try {
            const o = JSON.parse(text)
            lastUser = o.user || ""
            lastSession = o.session || ""
        } catch (e) {
            console.warn("archminimal: ignoring invalid state file")
        }
    }

    // Detached so the write survives Quickshell quitting on session launch.
    function save(user, session) {
        Quickshell.execDetached(["sh", "-c",
            'umask 022 && mkdir -p "$1" && printf "%s" "$2" > "$1/state.json.tmp" && mv "$1/state.json.tmp" "$1/state.json"',
            "sh", dir, JSON.stringify({ user: user, session: session })])
    }
}
