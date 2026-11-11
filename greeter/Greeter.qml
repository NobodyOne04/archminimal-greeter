// The Arch Minimal login screen: Quickshell UI, greetd for authentication
// and session start.
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Greetd

Item {
    id: root

    // Only the primary monitor's instance shows the form and talks to greetd.
    property bool interactive: true
    // Preview mode never authenticates, launches or powers off anything.
    property bool preview: false

    property color accent: Config.accent
    property color danger: Config.danger
    property color fg: Config.fg
    property color mute: Config.mute
    property string mono: Config.fontFamily

    property bool failed: false
    property string failMsg: ""
    property bool busy: false
    property bool sessionOpen: false
    property string pendingPassword: ""
    property string pendingUser: ""
    property real shakeX: 0
    property string timeStr: ""
    property string dateStr: ""

    // ---------- WALLPAPER ----------
    Rectangle {
        anchors.fill: parent
        color: Config.bgColor
    }

    Image {
        id: bg
        anchors.fill: parent
        source: Config.background
        fillMode: Image.PreserveAspectCrop
        smooth: true
        asynchronous: false
    }

    // soft vignette (top and bottom)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0;  color: "#77000000" }
            GradientStop { position: 0.30; color: "#00000000" }
            GradientStop { position: 0.70; color: "#00000000" }
            GradientStop { position: 1.0;  color: "#88000000" }
        }
    }

    // very faint scanlines
    Canvas {
        anchors.fill: parent
        visible: Config.scanlines
        opacity: 0.05
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = "#000000"
            for (let y = 0; y < height; y += 4)
                ctx.fillRect(0, y, width, 1)
        }
    }

    // ---------- LOGO GLITCH (brief flicker every ~2.5s) ----------
    // As in the original design: two tinted, shifted copies of the wallpaper
    // flash over the logo. Cyan over the upper band; red over a lower band
    // that overlaps the bottom of the cyan one, 60 ms behind it.
    // One timeline drives both layers so red always overlaps cyan on screen
    // (with separate animations red only lit up while cyan was off and was
    // easy to miss).
    component Ghost: Item {
        id: ghost
        property real bandTop
        property real bandH
        property color tint
        property real dx: 0
        x: root.width * 0.32
        y: root.height * bandTop
        width: root.width * 0.36
        height: root.height * bandH
        clip: true
        opacity: 0
        visible: Config.glitch

        Image {
            x: -ghost.x + ghost.dx
            y: -ghost.y
            width: root.width
            height: root.height
            source: bg.source
            fillMode: Image.PreserveAspectCrop
        }
        Rectangle { anchors.fill: parent; color: ghost.tint; opacity: 0.22 }
    }

    Ghost { id: ghostCyan; tint: root.accent; bandTop: 0.38; bandH: 0.18 }
    Ghost { id: ghostRed;  tint: root.danger; bandTop: 0.52; bandH: 0.12 }

    SequentialAnimation {
        running: Config.glitch
        loops: Animation.Infinite
        PauseAnimation { duration: 2200 }
        ScriptAction { script: { ghostCyan.dx = -6; ghostCyan.opacity = 0.7 } }
        PauseAnimation { duration: 60 }
        ScriptAction { script: { ghostRed.dx = 6; ghostRed.opacity = 0.75 } }
        PauseAnimation { duration: 60 }
        ScriptAction { script: { ghostCyan.opacity = 0 } }
        PauseAnimation { duration: 60 }
        ScriptAction { script: { ghostCyan.dx = 5; ghostCyan.opacity = 0.6; ghostRed.dx = -4 } }
        PauseAnimation { duration: 70 }
        ScriptAction { script: { ghostRed.opacity = 0 } }
        PauseAnimation { duration: 50 }
        ScriptAction { script: { ghostCyan.opacity = 0; ghostCyan.dx = 0; ghostRed.dx = 0 } }
    }

    // ---------- CORNER MARKS ----------
    Repeater {
        model: 4
        Item {
            required property int index
            width: 16; height: 16
            opacity: 0.45
            x: (index % 2 === 0) ? 20 : root.width - 36
            y: (index < 2) ? 20 : root.height - 36
            Rectangle {   // horizontal arm
                width: 16; height: 1; color: root.accent
                anchors.top: index < 2 ? parent.top : undefined
                anchors.bottom: index >= 2 ? parent.bottom : undefined
            }
            Rectangle {   // vertical arm
                width: 1; height: 16; color: root.accent
                anchors.left: index % 2 === 0 ? parent.left : undefined
                anchors.right: index % 2 === 1 ? parent.right : undefined
            }
        }
    }

    // ---------- HEADER + CLOCK ----------
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            const d = new Date()
            root.timeStr = Qt.formatDateTime(d, "HH:mm")
            root.dateStr = Qt.formatDateTime(d, "ddd dd MMM").toUpperCase()
        }
    }

    Text {
        anchors { top: parent.top; left: parent.left; topMargin: 44; leftMargin: 44 }
        text: Config.headerText + (root.preview ? "  [preview]" : "")
        color: root.mute
        font { family: root.mono; pixelSize: 12; letterSpacing: 2 }
    }

    Column {
        anchors { top: parent.top; right: parent.right; topMargin: 40; rightMargin: 44 }
        spacing: 2
        Text {
            anchors.right: parent.right
            text: root.timeStr
            color: root.fg
            font { family: root.mono; pixelSize: 22; weight: Font.Light; letterSpacing: 3 }
        }
        Text {
            anchors.right: parent.right
            text: root.dateStr
            color: root.mute
            font { family: root.mono; pixelSize: 11; letterSpacing: 2 }
        }
    }

    // ---------- LOGIN (sits under the logo) ----------
    Column {
        id: loginCol
        visible: root.interactive
        width: 300
        x: (root.width - width) / 2
        y: root.height * Config.loginY
        spacing: 12
        transform: Translate { x: root.shakeX }

        // glowing accent line
        Item {
            width: parent.width; height: 10
            Rectangle {
                width: 36; height: 3; color: root.accent; opacity: 0.2
                anchors.horizontalCenter: parent.horizontalCenter; y: 0
            }
            Rectangle {
                width: 36; height: 1; color: root.accent
                anchors.horizontalCenter: parent.horizontalCenter; y: 1
            }
        }

        // username ("login")
        Item {
            width: parent.width; height: 30
            TextField {
                id: userField
                anchors.fill: parent
                text: Config.rememberUser ? (LoginState.lastUser || Config.defaultUser) : Config.defaultUser
                enabled: !root.busy
                horizontalAlignment: TextInput.AlignHCenter
                color: root.fg
                selectionColor: root.accent
                selectedTextColor: "#000000"
                font { family: root.mono; pixelSize: 13; letterSpacing: 4; capitalization: Font.AllUppercase }
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: userField.activeFocus ? root.accent : "transparent"
                    }
                }
                KeyNavigation.tab: passField
                onAccepted: { root.log("user field: Enter"); passField.forceActiveFocus() }
            }
            Text {
                anchors.centerIn: parent
                visible: userField.text.length === 0
                text: "login"
                color: root.mute
                font { family: root.mono; pixelSize: 13; letterSpacing: 4; capitalization: Font.AllUppercase }
            }
        }

        // password
        Item {
            width: parent.width; height: 36
            TextField {
                id: passField
                anchors.fill: parent
                leftPadding: 30
                rightPadding: 30
                enabled: !root.busy
                echoMode: TextInput.Password
                passwordCharacter: "•"
                horizontalAlignment: TextInput.AlignHCenter
                color: root.fg
                selectionColor: root.accent
                selectedTextColor: "#000000"
                font { family: root.mono; pixelSize: 14; letterSpacing: 6 }
                background: Rectangle {
                    color: "transparent"
                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 1
                        color: passField.activeFocus ? root.accent : "#4a4c54"
                    }
                }
                KeyNavigation.backtab: userField
                onAccepted: { root.log("password field: Enter"); root.doLogin() }
                onTextChanged: root.failed = false
            }
            Text {
                anchors.centerIn: parent
                visible: passField.text.length === 0
                text: "password"
                color: root.mute
                font { family: root.mono; pixelSize: 12; letterSpacing: 3 }
            }
            Text {
                anchors { right: parent.right; verticalCenter: parent.verticalCenter }
                text: "→"
                color: (goMa.containsMouse || passField.activeFocus) ? root.accent : root.mute
                font { family: root.mono; pixelSize: 16 }
                MouseArea {
                    id: goMa
                    anchors.fill: parent
                    anchors.margins: -6
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.doLogin()
                }
            }
        }

        // status line
        Item {
            width: parent.width; height: 16
            Row {
                anchors.centerIn: parent
                spacing: 4
                Text {
                    text: root.failed ? (root.failMsg || "authentication failed")
                                      : root.busy ? "auth::pending" : "sys::ready"
                    color: root.failed ? root.danger : root.mute
                    font { family: root.mono; pixelSize: 11; letterSpacing: 2 }
                }
                Rectangle {
                    visible: !root.failed
                    width: 7; height: 12
                    color: root.accent
                    SequentialAnimation on opacity {
                        loops: Animation.Infinite
                        NumberAnimation { to: 0; duration: 1 }
                        PauseAnimation { duration: root.busy ? 150 : 500 }
                        NumberAnimation { to: 1; duration: 1 }
                        PauseAnimation { duration: root.busy ? 150 : 500 }
                    }
                }
            }
        }
    }

    // ---------- BOTTOM BAR ----------
    Text {
        anchors { bottom: parent.bottom; left: parent.left; bottomMargin: 44; leftMargin: 44 }
        visible: root.interactive && Config.showSession && Sessions.list.length > 0
        text: Sessions.selected ? Sessions.selected.name : ""
        color: sessMa.containsMouse ? root.accent : root.mute
        font { family: root.mono; pixelSize: 11; letterSpacing: 2; capitalization: Font.AllUppercase }
        MouseArea {
            id: sessMa
            anchors.fill: parent
            anchors.margins: -6
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: Sessions.next()
        }
    }

    Row {
        visible: root.interactive && Config.showPower
        anchors { bottom: parent.bottom; right: parent.right; bottomMargin: 44; rightMargin: 44 }
        spacing: 18
        Text {
            text: "reboot"
            color: rbMa.containsMouse ? root.accent : root.mute
            font { family: root.mono; pixelSize: 11; letterSpacing: 2; capitalization: Font.AllUppercase }
            MouseArea {
                id: rbMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.power("reboot")
            }
        }
        Text {
            text: "shutdown"
            color: pwMa.containsMouse ? root.danger : root.mute
            font { family: root.mono; pixelSize: 11; letterSpacing: 2; capitalization: Font.AllUppercase }
            MouseArea {
                id: pwMa
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.power("poweroff")
            }
        }
    }

    // ---------- LOGIC ----------
    // Step log (never the password): /var/cache/archminimal-greeter/greeter.log
    function log(msg) { console.info("archminimal: " + msg) }

    function fail(message) {
        busy = false
        pendingPassword = ""
        passField.text = ""      // clear first: textChanged resets "failed"
        failMsg = message
        failed = true
        passField.forceActiveFocus()
        shake.start()
    }

    function power(action) {
        if (preview) {
            fail("preview: " + action + " skipped")
            return
        }
        Quickshell.execDetached(["systemctl", action])
    }

    function cancelSession() {
        if (!sessionOpen)
            return
        sessionOpen = false
        try {
            Greetd.cancelSession()
        } catch (e) {
            console.warn("archminimal: cancelSession:", e)
        }
    }

    function doLogin() {
        log("doLogin: busy=" + busy + " interactive=" + interactive + " user='" + userField.text.trim() + "'")
        if (busy || !interactive)
            return
        const user = userField.text.trim()
        if (user === "") {
            userField.forceActiveFocus()
            return
        }
        if (preview) {
            fail("preview: login disabled")
            return
        }
        if (!Greetd.available) {
            fail("greetd unavailable")
            return
        }
        if (Sessions.selected === null) {
            fail("no wayland session found")
            return
        }
        cancelSession()
        busy = true
        failed = false
        pendingUser = user
        pendingPassword = passField.text
        sessionOpen = true
        log("createSession(" + user + "), session " + Sessions.selected.id)
        Greetd.createSession(user)
    }

    Connections {
        target: Greetd
        enabled: root.interactive && !root.preview

        function onAuthMessage(message, error, responseRequired, echoResponse) {
            root.log("authMessage: '" + message + "' error=" + error + " responseRequired=" + responseRequired)
            if (!responseRequired) {
                if (error)
                    console.warn("archminimal: PAM:", message)
                return
            }
            // The password only ever answers a hidden prompt: a visible one (a username,
            // a one-time code asked before the password) would get it typed into the
            // wrong field. Such PAM setups aren't supported.
            if (root.passwordSent || echoResponse) {
                // A second prompt (e.g. a one-time code) is not supported.
                root.cancelSession()
                root.fail("unsupported prompt")
                return
            }
            root.passwordSent = true
            Greetd.respond(root.pendingPassword)
            root.pendingPassword = ""
        }

        function onAuthFailure(message) {
            root.log("authFailure: " + message)
            root.cancelSession()
            root.fail("")
        }

        function onReadyToLaunch() {
            const s = Sessions.selected
            root.log("readyToLaunch: starting " + s.id + ": " + JSON.stringify(Sessions.command(s)))
            LoginState.save(root.pendingUser, s.id)
            Greetd.launch(Sessions.command(s), Sessions.environment(s), true)
        }

        function onLaunched() { root.log("launched: greetd accepted the session; quitting") }

        function onError(error) {
            root.log("greetd error: " + error)
            root.cancelSession()
            root.fail("greetd: " + error)
        }
    }

    // true once the password was handed to greetd for the current attempt
    property bool passwordSent: false
    onBusyChanged: if (busy) passwordSent = false

    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -6; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: 6;  duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: -4; duration: 60 }
        NumberAnimation { target: root; property: "shakeX"; to: 0;  duration: 60 }
    }

    Component.onCompleted: {
        if (!interactive)
            return
        log("ready: preview=" + preview + " greetd=" + Greetd.available + " sessions=" + Sessions.list.length)
        if (userField.text === "")
            userField.forceActiveFocus()
        else
            passField.forceActiveFocus()
    }
}
