import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

// Rounded, padded container with an optional heading. Children go into the card body.
Rectangle {
    id: card

    property string title: ""
    default property alias content: body.data

    readonly property color ink: Kirigami.Theme.textColor

    Layout.fillWidth: true
    implicitHeight: body.implicitHeight + Kirigami.Units.largeSpacing * 2
    radius: Kirigami.Units.largeSpacing
    color: Qt.rgba(ink.r, ink.g, ink.b, 0.05)
    border.width: 1
    border.color: Qt.rgba(ink.r, ink.g, ink.b, 0.10)

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: Kirigami.Units.largeSpacing
        spacing: Kirigami.Units.smallSpacing

        QQC2.Label {
            Layout.fillWidth: true
            visible: card.title !== ""
            text: card.title
            font.bold: true
            opacity: 0.7
            elide: Text.ElideRight
        }
    }
}
