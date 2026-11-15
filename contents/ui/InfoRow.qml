import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami

RowLayout {
    id: root

    property string title
    property string detail
    property string badge
    property bool positive: true

    Layout.fillWidth: true
    spacing: Kirigami.Units.smallSpacing

    Rectangle {
        Layout.alignment: Qt.AlignVCenter
        implicitWidth: Kirigami.Units.smallSpacing * 2
        implicitHeight: implicitWidth
        radius: width / 2
        color: root.positive ? Kirigami.Theme.positiveTextColor : Kirigami.Theme.disabledTextColor
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 0

        QQC2.Label {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
        }
        QQC2.Label {
            Layout.fillWidth: true
            visible: text !== ""
            text: root.detail
            elide: Text.ElideRight
            font: Kirigami.Theme.smallFont
            opacity: 0.7
        }
    }

    QQC2.Label {
        visible: text !== ""
        text: root.badge
        font: Kirigami.Theme.smallFont
        opacity: 0.7
    }
}
