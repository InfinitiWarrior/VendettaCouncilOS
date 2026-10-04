import QtQuick 2.0
import calamares.slideshow 1.0

Presentation {
    id: presentation
    Timer { interval: 20000; running: true; repeat: true; onTriggered: presentation.goToNextSlide() }

    Slide {
        anchors.fill: parent
        Rectangle {
            anchors.fill: parent
            color: "#04090A"
            Text {
                anchors.centerIn: parent
                horizontalAlignment: Text.AlignHCenter
                color: "#37E6D8"
                font.pixelSize: 28
                text: "VENDETTA COUNCIL OS\n\nIdeas are bulletproof."
            }
        }
    }
}
