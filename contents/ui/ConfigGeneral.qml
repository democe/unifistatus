import QtQuick
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.kquickcontrols as KQuickControls
import org.kde.plasma.plasmoid

Kirigami.FormLayout {
    property alias cfg_consoleUrl: urlField.text
    property alias cfg_apiKey: keyField.text
    property alias cfg_siteId: siteField.text
    property alias cfg_pollSeconds: pollSpin.value
    property alias cfg_graphSeconds: graphSpin.value

    QQC2.TextField {
        id: urlField
        Kirigami.FormData.label: i18n("Console URL:")
        placeholderText: "https://192.168.1.1"
        inputMethodHints: Qt.ImhUrlCharactersOnly
    }

    Kirigami.PasswordField {
        id: keyField
        Kirigami.FormData.label: i18n("API key:")
    }

    QQC2.TextField {
        id: siteField
        Kirigami.FormData.label: i18n("Site ID:")
        placeholderText: i18n("Optional, defaults to the first site")
    }

    QQC2.SpinBox {
        id: pollSpin
        Kirigami.FormData.label: i18n("Refresh every:")
        from: 10
        to: 3600
        stepSize: 5
        textFromValue: (value) => i18n("%1 s", value)
    }

    QQC2.SpinBox {
        id: graphSpin
        Kirigami.FormData.label: i18n("Traffic graph every:")
        from: 1
        to: 60
        stepSize: 1
        textFromValue: (value) => i18n("%1 s", value)
    }

    KQuickControls.KeySequenceItem {
        Kirigami.FormData.label: i18n("Toggle popup:")
        keySequence: Plasmoid.globalShortcut
        onKeySequenceModified: Plasmoid.globalShortcut = keySequence
    }
}
