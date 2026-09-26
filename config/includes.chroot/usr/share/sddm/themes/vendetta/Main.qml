import QtQuick 2.15
import QtQuick.Controls 2.15
import SDDM 2.0

Rectangle {
    id: root
    color: "#04090A"
    property int session: sessionModel.lastIndex

    Image {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -90
        source: config.sigil || "assets/sigil.png"
        opacity: 0.30
        width: 300
        height: 300
        fillMode: Image.PreserveAspectFit
        smooth: true
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: 120
        spacing: 18
        width: 300

        TextField {
            id: username
            width: parent.width
            height: 34
            text: userModel.lastUser
            placeholderText: "user"
            color: "#CFE6E6"
            placeholderTextColor: "#5A6E70"
            font.family: "Chakra Petch"
            font.pixelSize: 14
            selectionColor: "#0C2A2A"
            selectedTextColor: "#CFE6E6"
            background: Item {
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: username.activeFocus ? "#37E6D8" : "#1B2A2C"
                }
            }
            KeyNavigation.tab: password
        }

        TextField {
            id: password
            width: parent.width
            height: 34
            echoMode: TextInput.Password
            placeholderText: "password"
            color: "#CFE6E6"
            placeholderTextColor: "#5A6E70"
            font.family: "Chakra Petch"
            font.pixelSize: 14
            selectionColor: "#0C2A2A"
            selectedTextColor: "#CFE6E6"
            background: Item {
                Rectangle {
                    anchors.bottom: parent.bottom
                    width: parent.width
                    height: 1
                    color: password.activeFocus ? "#37E6D8" : "#1B2A2C"
                }
            }
            onAccepted: sddm.login(username.text, password.text, root.session)
        }

        Text {
            id: message
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            color: "#D63C48"
            font.family: "Chakra Petch"
            font.pixelSize: 11
            font.capitalization: Font.AllUppercase
            font.letterSpacing: 2
        }
    }

    Connections {
        target: sddm
        function onLoginFailed() { message.text = "Authentication failed" }
        function onLoginSucceeded() { message.text = "" }
    }

    Component.onCompleted: password.forceActiveFocus()
}
