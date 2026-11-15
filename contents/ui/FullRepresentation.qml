import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2

import org.kde.kirigami as Kirigami
import org.kde.plasma.extras as PlasmaExtras

ColumnLayout {
    id: root

    required property var app

    readonly property var latest: app.trafficHistory.length > 0
        ? app.trafficHistory[app.trafficHistory.length - 1]
        : ({ rx: 0, tx: 0 })
    readonly property real peakBps: app.trafficHistory.reduce((m, s) => Math.max(m, s.rx, s.tx), 0)

    function formatRate(bps) {
        return bps >= 1e6 ? i18n("%1 Mb/s", (bps / 1e6).toFixed(1)) : i18n("%1 kb/s", Math.round(bps / 1e3));
    }

    Layout.minimumWidth: Kirigami.Units.gridUnit * 24
    Layout.preferredWidth: Kirigami.Units.gridUnit * 28
    Layout.minimumHeight: Kirigami.Units.gridUnit * 20
    Layout.preferredHeight: Kirigami.Units.gridUnit * 34
    Layout.maximumHeight: Kirigami.Units.gridUnit * 44
    spacing: Kirigami.Units.largeSpacing

    Layout.leftMargin: Kirigami.Units.smallSpacing
    Layout.rightMargin: Kirigami.Units.smallSpacing
    Layout.topMargin: Kirigami.Units.smallSpacing
    Layout.bottomMargin: Kirigami.Units.smallSpacing

    // Header: site, controller details, status pill
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.mediumSpacing

        Kirigami.Icon {
            Layout.preferredWidth: Kirigami.Units.iconSizes.large
            Layout.preferredHeight: Kirigami.Units.iconSizes.large
            source: app.status === "error" ? "dialog-warning"
                  : app.connected ? "network-wired"
                  : "network-offline"
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 0

            PlasmaExtras.Heading {
                Layout.fillWidth: true
                level: 3
                elide: Text.ElideRight
                text: app.siteName || i18n("UniFi Console")
            }
            QQC2.Label {
                Layout.fillWidth: true
                elide: Text.ElideRight
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                text: app.connected
                    ? i18n("Controller %1", app.consoleVersion)
                    : (app.status === "unconfigured" ? i18n("Not configured") : app.errorText)
            }
        }

        Rectangle {
            id: pill
            readonly property color tint: app.status === "error" ? Kirigami.Theme.negativeTextColor
                : app.connected ? Kirigami.Theme.positiveTextColor
                : Kirigami.Theme.disabledTextColor

            Layout.alignment: Qt.AlignVCenter
            implicitWidth: pillText.implicitWidth + Kirigami.Units.largeSpacing * 2
            implicitHeight: pillText.implicitHeight + Kirigami.Units.smallSpacing * 2
            radius: height / 2
            color: Qt.rgba(tint.r, tint.g, tint.b, 0.18)

            QQC2.Label {
                id: pillText
                anchors.centerIn: parent
                color: pill.tint
                font.bold: true
                text: app.connected ? i18n("Connected")
                    : app.status === "error" ? i18n("Unavailable")
                    : i18n("Not configured")
            }
        }
    }

    // Summary tiles
    RowLayout {
        Layout.fillWidth: true
        spacing: Kirigami.Units.smallSpacing

        Repeater {
            model: [
                { label: i18n("Devices"), value: app.onlineCount + "/" + app.devices.length },
                { label: i18n("Clients"), value: String(app.clientCount) },
                { label: i18n("Networks"), value: String(app.networks.length) },
                { label: i18n("Wi-Fi"), value: String(app.wifi.length) }
            ]

            delegate: Card {
                required property var modelData

                Layout.fillWidth: true
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    PlasmaExtras.Heading {
                        Layout.alignment: Qt.AlignHCenter
                        level: 2
                        text: modelData.value
                    }
                    QQC2.Label {
                        Layout.alignment: Qt.AlignHCenter
                        opacity: 0.6
                        font: Kirigami.Theme.smallFont
                        text: modelData.label
                    }
                }
            }
        }
    }

    // Traffic: gateway uplink graph with ISP line
    Card {
        title: i18n("Internet traffic")

        RowLayout {
            Layout.fillWidth: true
            spacing: Kirigami.Units.largeSpacing

            QQC2.Label {
                color: Kirigami.Theme.highlightColor
                font.bold: true
                text: i18n("↓ %1", root.formatRate(root.latest.rx))
            }
            QQC2.Label {
                color: Kirigami.Theme.positiveTextColor
                font.bold: true
                text: i18n("↑ %1", root.formatRate(root.latest.tx))
            }
            Item { Layout.fillWidth: true }
            QQC2.Label {
                opacity: 0.6
                font: Kirigami.Theme.smallFont
                text: i18n("peak %1", root.formatRate(root.peakBps))
            }
        }

        Canvas {
            id: graph
            Layout.fillWidth: true
            Layout.preferredHeight: Kirigami.Units.gridUnit * 6

            readonly property color downColor: Kirigami.Theme.highlightColor
            readonly property color upColor: Kirigami.Theme.positiveTextColor
            readonly property color gridColor: Kirigami.Theme.textColor

            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            Connections {
                target: app
                function onTrafficHistoryChanged() { graph.requestPaint(); }
            }

            onPaint: {
                const ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);

                ctx.strokeStyle = Qt.rgba(gridColor.r, gridColor.g, gridColor.b, 0.12);
                ctx.lineWidth = 1;
                ctx.beginPath();
                for (let i = 1; i < 4; i++) {
                    const y = Math.round(height * i / 4) + 0.5;
                    ctx.moveTo(0, y);
                    ctx.lineTo(width, y);
                }
                ctx.stroke();

                const data = app.trafficHistory;
                if (data.length < 2)
                    return;

                const peak = Math.max(1, root.peakBps);
                const step = width / (app.historyLength - 1);
                const plot = (key, color) => {
                    ctx.beginPath();
                    data.forEach((s, i) => {
                        const x = width - (data.length - 1 - i) * step;
                        const y = height - 3 - (s[key] / peak) * (height - 6);
                        if (i === 0) ctx.moveTo(x, y);
                        else ctx.lineTo(x, y);
                    });
                    ctx.strokeStyle = color;
                    ctx.lineWidth = 2;
                    ctx.lineJoin = "round";
                    ctx.stroke();
                };
                plot("rx", downColor);
                plot("tx", upColor);
            }
        }

        QQC2.Label {
            Layout.fillWidth: true
            visible: (app.isp.name ?? "") !== ""
            elide: Text.ElideRight
            opacity: 0.6
            font: Kirigami.Theme.smallFont
            text: [
                app.isp.name,
                app.isp.asn ? "AS" + app.isp.asn : "",
                (app.isp.latency ?? null) !== null ? i18n("%1 ms latency", app.isp.latency) : ""
            ].filter(Boolean).join(" · ")
        }
    }

    // Scrolling detail cards
    QQC2.ScrollView {
        id: scroll
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        contentWidth: availableWidth
        contentHeight: sections.implicitHeight

        QQC2.ScrollBar.vertical.policy: QQC2.ScrollBar.AsNeeded
        QQC2.ScrollBar.horizontal.policy: QQC2.ScrollBar.AlwaysOff

        ColumnLayout {
            id: sections
            width: scroll.availableWidth
            spacing: Kirigami.Units.largeSpacing

            Card {
                title: i18n("WAN")
                visible: app.wans.length > 0
                Repeater {
                    model: app.wans
                    delegate: InfoRow {
                        required property var modelData
                        title: modelData.name ?? ""
                        detail: modelData.ipAddress ?? ""
                        badge: "↓ " + root.formatRate(modelData.rxBps) + "   ↑ " + root.formatRate(modelData.txBps)
                        positive: modelData.state === "ONLINE"
                    }
                }
            }

            Card {
                title: i18n("Devices · %1 of %2 online", app.onlineCount, app.devices.length)
                visible: app.devices.length > 0
                Repeater {
                    model: app.devices
                    delegate: InfoRow {
                        required property var modelData
                        title: modelData.name ?? ""
                        detail: [modelData.model, modelData.ipAddress].filter(Boolean).join(" · ")
                        badge: modelData.state ?? ""
                        positive: modelData.state === "ONLINE"
                    }
                }
            }

            Card {
                title: i18n("Networks & VLANs")
                visible: app.networks.length > 0
                Repeater {
                    model: app.networks
                    delegate: InfoRow {
                        required property var modelData
                        title: modelData.name ?? ""
                        detail: modelData.vlanId !== undefined ? i18n("VLAN %1", modelData.vlanId) : ""
                        badge: modelData.management ?? ""
                        positive: modelData.enabled !== false
                    }
                }
            }

            Card {
                title: i18n("Wi-Fi")
                visible: app.wifi.length > 0
                Repeater {
                    model: app.wifi
                    delegate: InfoRow {
                        required property var modelData
                        title: modelData.name ?? ""
                        detail: (modelData.securityConfiguration?.type ?? "").replace(/_/g, " ")
                        badge: modelData.enabled === false ? i18n("Disabled") : ""
                        positive: modelData.enabled !== false
                    }
                }
            }
        }
    }
}
