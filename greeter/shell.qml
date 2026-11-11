// Arch Minimal greeter for greetd, drawn by Quickshell inside a minimal
// Hyprland instance (see ../system/hyprland.lua).
//
// Real mode (started by greetd, GREETD_SOCK is set): one full-screen overlay
// per monitor; the login form lives on the primary monitor, the others show
// the wallpaper only.
// Preview mode (run from your desktop with `make preview`): a normal window,
// nothing is authenticated and nothing is rebooted. Escape closes it.
import QtQuick
import Quickshell
import Quickshell.Wayland

ShellRoot {
    id: shell

    readonly property bool preview: !Quickshell.env("GREETD_SOCK")

    function isPrimary(screen) {
        const wanted = Config.primaryScreen
        if (wanted !== "") {
            const match = Quickshell.screens.some(s => s.name === wanted)
            if (match)
                return screen.name === wanted
        }
        return Quickshell.screens.length > 0 && screen === Quickshell.screens[0]
    }

    // ---------- greeter: one layer-shell surface per monitor ----------
    Variants {
        model: shell.preview ? [] : Quickshell.screens

        PanelWindow {
            id: panel
            required property var modelData
            readonly property bool primary: shell.isPrimary(modelData)

            screen: modelData
            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            color: Config.bgColor
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "archminimal-greeter"
            WlrLayershell.keyboardFocus: primary ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

            Greeter {
                anchors.fill: parent
                interactive: panel.primary
                preview: false
            }
        }
    }

    // ---------- preview: a plain window ----------
    LazyLoader {
        active: shell.preview

        FloatingWindow {
            implicitWidth: 1280
            implicitHeight: 720
            color: Config.bgColor
            title: "archminimal greeter — preview"

            Greeter {
                anchors.fill: parent
                interactive: true
                preview: true
                focus: true
                Keys.onEscapePressed: Qt.quit()
            }
        }
    }
}
