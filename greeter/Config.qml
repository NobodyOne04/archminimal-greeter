// Settings from /etc/archminimal-greeter/config.json (or $ARCHMINIMAL_CONFIG).
// Every key is optional; a missing or broken file falls back to defaults.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: cfg

    readonly property string path: Quickshell.env("ARCHMINIMAL_CONFIG") || "/etc/archminimal-greeter/config.json"
    property var data: ({})

    function get(key, def) {
        const v = data[key]
        return (v === undefined || v === null || v === "") ? def : v
    }

    // Absolute paths are used as-is; anything else is relative to the greeter.
    function resolve(p) {
        return p.startsWith("/") ? "file://" + p : Qt.resolvedUrl(p)
    }

    readonly property url background: resolve(get("background", "background.png"))
    readonly property color bgColor: get("bgColor", "#28292d")
    readonly property color fg: get("fg", "#d0d2d0")
    readonly property color mute: get("mute", "#7d8088")
    readonly property color accent: get("accent", "#00e5ff")
    readonly property color danger: get("danger", "#ff2a6d")
    readonly property string fontFamily: get("fontFamily", "JetBrains Mono")
    readonly property string headerText: get("headerText", "ARCH//LINUX")
    readonly property bool rememberUser: get("rememberUser", true)
    readonly property string defaultUser: get("defaultUser", "")
    readonly property bool showSession: get("showSession", false)
    readonly property string defaultSession: get("defaultSession", "")
    readonly property bool glitch: get("glitch", true)
    readonly property bool scanlines: get("scanlines", true)
    readonly property bool showPower: get("showPower", true)
    readonly property string primaryScreen: get("primaryScreen", "")
    readonly property real loginY: get("loginY", 0.70)

    FileView {
        id: file
        path: cfg.path
        blockLoading: true
    }

    Component.onCompleted: {
        const text = file.text()
        if (!text)
            return
        try {
            data = JSON.parse(text)
        } catch (e) {
            console.warn("archminimal: ignoring invalid config", cfg.path, ":", e)
        }
    }
}
