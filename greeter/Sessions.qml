// Installed Wayland sessions, read from /usr/share/wayland-sessions by
// list-sessions.sh. X11 sessions are not offered: greetd starts the session
// directly, without an X server.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: sessions

    // [{ id, name, desktopNames, exec }]
    property var list: []
    property int current: 0
    readonly property var selected: list.length > 0 ? list[current] : null

    function next() {
        if (list.length > 0)
            current = (current + 1) % list.length
    }

    function pickDefault() {
        const prefer = [LoginState.lastSession, Config.defaultSession]
        for (const id of prefer) {
            const i = list.findIndex(s => s.id === id)
            if (id && i >= 0) {
                current = i
                return
            }
        }
        current = 0
    }

    // argv for greetd: the desktop Exec line run by sh, with field codes
    // such as %U removed. The session's output goes to
    // ~/.local/state/archminimal-session.log (overwritten at each login), so a
    // session that dies right after login leaves a trace (`make diagnose`).
    // single-quote a string for /bin/sh
    function shq(v) { return "'" + String(v).replace(/'/g, "'\\''") + "'" }

    // greetd does NOT exec this list as argv: it runs
    //   /bin/sh -c "<profile>; exec " + cmd.join(" ")
    // so the command must be ONE correctly quoted shell string. (Passing
    // ["/bin/sh","-c","exec X"] turned into `sh -c exec X`, which runs nothing
    // and ended the session instantly: back to the login screen.)
    function command(s) {
        const exec = s.exec.replace(/%[a-zA-Z%]/g, "").trim()
        // $1 = Exec line, $2 = session id. Only display-related env is logged.
        const script =
            'log="$HOME/.local/state/archminimal-session.log"; mkdir -p "${log%/*}"; ' +
            '{ echo "== $(date) session: $2"; echo "exec: $1"; ' +
            "env | grep -E '^(XDG_|WAYLAND|DISPLAY=|PATH=|HOME=|USER=|SHELL=|LANG=|DBUS_)' | sort; echo '=='; } >\"$log\" 2>&1; " +
            'eval "exec $1" >>"$log" 2>&1'
        return ["/bin/sh -c " + shq(script) + " sh " + shq(exec) + " " + shq(s.id)]
    }

    function environment(s) {
        const env = ["XDG_SESSION_TYPE=wayland", "XDG_SESSION_DESKTOP=" + s.id]
        if (s.desktopNames)
            env.push("XDG_CURRENT_DESKTOP=" + s.desktopNames.replace(/;$/, "").replace(/;/g, ":"))
        return env
    }

    Process {
        running: true
        command: ["sh", Qt.resolvedUrl("list-sessions.sh").toString().replace(/^file:\/\//, "")]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of this.text.split("\n")) {
                    const f = line.split("\t")
                    if (f.length >= 4 && f[3] !== "")
                        out.push({ id: f[0], name: f[1] || f[0], desktopNames: f[2], exec: f[3] })
                }
                out.sort((a, b) => a.name.localeCompare(b.name))
                sessions.list = out
                sessions.pickDefault()
            }
        }
    }
}
