import QtQuick 2.15
import QtQuick.Controls 2.15
// Note: sddm, sessionModel, userModel and config are injected as context
// properties by the greeter — do NOT `import SDDM`, that module doesn't exist
// in SDDM 0.21 and importing it makes the whole theme fail to load (→ white
// fallback greeter). The bundled Breeze theme uses them the same way.

Rectangle {
    id: root
    color: "#04090A"

    // palette
    readonly property color cyan:   "#37E6D8"
    readonly property color text:   "#CFE6E6"
    readonly property color muted:  "#5A6E70"
    readonly property color line:   "#1B2A2C"
    readonly property color panelC: "#0A1416"
    readonly property color error:  "#D63C48"

    // ---- backdrop: big dim sigil + faint scanlines ----
    Image {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -40
        source: config.sigil || "assets/sigil.png"
        width: 420; height: 420
        opacity: 0.06
        fillMode: Image.PreserveAspectFit
        smooth: true
    }
    Column {
        anchors.fill: parent
        spacing: 3
        Repeater {
            model: Math.ceil(root.height / 3)
            Rectangle { width: root.width; height: 1; color: root.cyan; opacity: 0.018 }
        }
    }

    // ---- clock ----
    Column {
        id: clockCol
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.height * 0.12
        spacing: 4
        Text {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.text
            font.family: "Chakra Petch"; font.pixelSize: 66; font.weight: Font.Light
        }
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.muted
            font.family: "Chakra Petch"; font.pixelSize: 13
            font.letterSpacing: 4; font.capitalization: Font.AllUppercase
        }
    }
    Timer {
        interval: 1000; running: true; repeat: true; triggeredOnStart: true
        onTriggered: {
            var d = new Date()
            clock.text = Qt.formatTime(d, "hh:mm")
            dateText.text = Qt.formatDate(d, "dddd  d  MMMM")
        }
    }

    // ---- login panel ----
    Rectangle {
        id: panel
        width: 360
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 40
        height: content.height + 56
        color: root.panelC
        border.color: root.line
        border.width: 1

        // top accent bar
        Rectangle { anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; height: 2; color: root.cyan }

        Column {
            id: content
            anchors.centerIn: parent
            width: parent.width - 56
            spacing: 16

            Image {
                anchors.horizontalCenter: parent.horizontalCenter
                source: config.sigil || "assets/sigil.png"
                width: 56; height: 56
                fillMode: Image.PreserveAspectFit; smooth: true
            }
            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "VENDETTA COUNCIL OS"
                color: root.text
                font.family: "Chakra Petch"; font.pixelSize: 15
                font.letterSpacing: 3; font.weight: Font.Medium
            }

            TextField {
                id: username
                width: parent.width; height: 36
                text: userModel.lastUser
                placeholderText: "user"
                color: root.text; placeholderTextColor: root.muted
                font.family: "Chakra Petch"; font.pixelSize: 14
                selectionColor: "#0C2A2A"; selectedTextColor: root.text
                background: Rectangle {
                    color: "#060D0E"
                    border.color: username.activeFocus ? root.cyan : root.line
                    border.width: 1
                }
                leftPadding: 10
                KeyNavigation.tab: password
            }

            TextField {
                id: password
                width: parent.width; height: 36
                echoMode: TextInput.Password
                placeholderText: "password"
                color: root.text; placeholderTextColor: root.muted
                font.family: "Chakra Petch"; font.pixelSize: 14
                selectionColor: "#0C2A2A"; selectedTextColor: root.text
                background: Rectangle {
                    color: "#060D0E"
                    border.color: password.activeFocus ? root.cyan : root.line
                    border.width: 1
                }
                leftPadding: 10
                onAccepted: root.doLogin()
            }

            Button {
                id: loginBtn
                width: parent.width; height: 38
                text: "UNLOCK"
                onClicked: root.doLogin()
                contentItem: Text {
                    text: loginBtn.text
                    color: loginBtn.down ? "#04090A" : "#04090A"
                    font.family: "Chakra Petch"; font.pixelSize: 14
                    font.letterSpacing: 4; font.weight: Font.Medium
                    horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    color: loginBtn.down ? Qt.darker(root.cyan, 1.2)
                          : loginBtn.hovered ? Qt.lighter(root.cyan, 1.05) : root.cyan
                }
            }

            Text {
                id: message
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                color: root.error
                font.family: "Chakra Petch"; font.pixelSize: 11
                font.capitalization: Font.AllUppercase; font.letterSpacing: 2
                wrapMode: Text.WordWrap
            }
        }
    }

    // hidden session model reader (drives the flat cycler below)
    ComboBox {
        id: sessionBox
        visible: false
        model: sessionModel
        textRole: "name"
        currentIndex: sessionModel.lastIndex
    }

    function doLogin() {
        sddm.login(username.text, password.text, sessionBox.currentIndex)
    }

    // ---- bottom bar: session (left) + power (right) ----
    Text {
        id: sessionSel
        anchors.left: parent.left; anchors.bottom: parent.bottom
        anchors.leftMargin: 28; anchors.bottomMargin: 22
        text: "◈ " + sessionBox.currentText
        color: sessionMouse.containsMouse ? root.cyan : root.muted
        font.family: "Chakra Petch"; font.pixelSize: 12; font.letterSpacing: 1
        MouseArea {
            id: sessionMouse
            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
            onClicked: sessionBox.currentIndex = (sessionBox.currentIndex + 1) % sessionBox.count
        }
    }

    Row {
        anchors.right: parent.right; anchors.bottom: parent.bottom
        anchors.rightMargin: 28; anchors.bottomMargin: 22
        spacing: 22

        Text {
            visible: sddm.canReboot
            text: "RESTART"
            color: rebootMouse.containsMouse ? root.cyan : root.muted
            font.family: "Chakra Petch"; font.pixelSize: 12; font.letterSpacing: 2
            MouseArea { id: rebootMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sddm.reboot() }
        }
        Text {
            visible: sddm.canPowerOff
            text: "SHUT DOWN"
            color: powerMouse.containsMouse ? root.cyan : root.muted
            font.family: "Chakra Petch"; font.pixelSize: 12; font.letterSpacing: 2
            MouseArea { id: powerMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: sddm.powerOff() }
        }
    }

    // tagline
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom; anchors.bottomMargin: 24
        text: "IDEAS ARE BULLETPROOF"
        color: root.line
        font.family: "Chakra Petch"; font.pixelSize: 11; font.letterSpacing: 4
    }

    Connections {
        target: sddm
        function onLoginFailed() { message.text = "Authentication failed"; password.text = ""; password.forceActiveFocus() }
        function onLoginSucceeded() { message.text = "" }
    }

    Component.onCompleted: password.forceActiveFocus()
}
