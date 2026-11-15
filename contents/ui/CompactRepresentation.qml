import QtQuick

import org.kde.kirigami as Kirigami

Item {
    id: root

    required property var app
    required property bool connected
    required property bool hasError

    implicitWidth: Kirigami.Units.iconSizes.medium
    implicitHeight: Kirigami.Units.iconSizes.medium

    Kirigami.Icon {
        anchors.fill: parent
        source: root.hasError ? "dialog-warning"
              : root.connected ? "network-wired"
              : "network-offline"
        active: hover.containsMouse
    }

    MouseArea {
        id: hover
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton
        onClicked: root.app.expanded = !root.app.expanded
    }
}
