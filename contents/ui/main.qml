import QtQuick

import org.kde.kirigami as Kirigami
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    // "unconfigured" | "ok" | "error"
    property string status: "unconfigured"
    property string errorText: ""
    property string consoleVersion: ""
    property string siteName: ""
    property string siteId: ""
    property var devices: []
    property var networks: []
    property var wifi: []
    property var wans: []
    property var gateways: []
    property var isp: ({})
    property int clientCount: 0

    // Gateway uplink throughput, one sample per graph tick (bits per second).
    // 300 samples is about 5 minutes at the default 1 s graph interval.
    readonly property int historyLength: 300
    property var trafficHistory: []
    property bool sampling: false

    readonly property bool connected: status === "ok"
    readonly property int onlineCount: devices.filter(d => d.state === "ONLINE").length

    Plasmoid.title: i18n("UniFi Status")
    toolTipMainText: connected ? siteName : i18n("UniFi console")
    toolTipSubText: connected
        ? i18n("%1 of %2 devices online", onlineCount, devices.length)
        : (status === "unconfigured" ? i18n("Configure the console URL and API key") : errorText)

    compactRepresentation: CompactRepresentation {
        app: root
        connected: root.connected
        hasError: root.status === "error"
    }

    fullRepresentation: FullRepresentation {
        app: root
    }

    UnifiApi {
        id: api
        baseUrl: Plasmoid.configuration.consoleUrl
        apiKey: Plasmoid.configuration.apiKey
    }

    // Full refresh: info, sites, devices, networks, Wi-Fi, clients.
    Timer {
        interval: Math.max(10, Plasmoid.configuration.pollSeconds) * 1000
        running: api.baseUrl !== "" && api.apiKey !== ""
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    // Throughput sampling: gateway statistics only, at its own interval.
    Timer {
        interval: Math.max(1, Plasmoid.configuration.graphSeconds) * 1000
        running: root.connected && root.gateways.length > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sampleTraffic()
    }

    Connections {
        target: Plasmoid.configuration
        function onConsoleUrlChanged() { root.refresh(); }
        function onApiKeyChanged() { root.refresh(); }
        function onSiteIdChanged() { root.refresh(); }
    }

    function fail(message) {
        status = "error";
        errorText = message;
    }

    function refresh() {
        if (api.baseUrl === "" || api.apiKey === "") {
            status = "unconfigured";
            return;
        }

        api.get("info", null, info => {
            consoleVersion = info.applicationVersion ?? "";

            api.all("sites", sites => {
                const wanted = Plasmoid.configuration.siteId;
                const site = sites.find(s => s.id === wanted) ?? sites[0];
                if (!site) {
                    fail(i18n("No sites found on the console"));
                    return;
                }
                siteName = site.name ?? "";
                siteId = site.id;
                status = "ok";
                loadSite(site.id);
            }, fail);
        }, fail);
    }

    function loadSite(id) {
        const base = "sites/" + id + "/";
        api.all(base + "devices", list => {
            devices = list;
            // The Integration API has no WAN object. Gateways are identified by model prefix (heuristic);
            // their uplink throughput comes from the per-device statistics endpoint.
            gateways = list.filter(d => /^(UDM|UDR|UXG|UCG|UDW)/.test(d.model ?? ""));
            if (gateways.length === 0)
                wans = [];
            sampleTraffic();
        }, fail);
        api.all(base + "networks", list => networks = list, fail);
        api.all(base + "wifi/broadcasts", list => wifi = list, fail);
        api.get(base + "clients", { limit: 1 }, r => clientCount = r.totalCount ?? 0, fail);
        loadIsp();
    }

    // ISP name and latency come from the legacy health endpoint. Failures are ignored so the
    // rest of the widget keeps working.
    function loadIsp() {
        api.legacy("s/default/stat/health", r => {
            const w = (r.data ?? []).find(x => x.subsystem === "wan");
            if (!w)
                return;
            isp = {
                name: w.isp_name ?? "",
                organization: w.isp_organization ?? "",
                asn: w.asn ?? "",
                latency: w.uptime_stats?.WAN?.latency_average ?? null
            };
        }, () => {});
    }

    // Reads uplink rates for every gateway, then publishes WAN rows and one history sample.
    // Skips the round if the previous one is still in flight.
    function sampleTraffic() {
        if (sampling || gateways.length === 0 || siteId === "")
            return;
        sampling = true;

        const list = gateways;
        const base = "sites/" + siteId + "/";
        const results = new Array(list.length);
        let pending = list.length;

        const done = () => {
            if (--pending > 0)
                return;
            wans = results;
            recordTraffic(results);
            sampling = false;
        };

        list.forEach((d, i) => {
            const row = { name: d.name ?? "", ipAddress: d.ipAddress ?? "", state: d.state ?? "", rxBps: 0, txBps: 0 };
            results[i] = row;
            api.get(base + "devices/" + d.id + "/statistics/latest", null, s => {
                row.rxBps = s.uplink?.rxRateBps ?? 0;
                row.txBps = s.uplink?.txRateBps ?? 0;
                done();
            }, done);
        });
    }

    function recordTraffic(entries) {
        let rx = 0;
        let tx = 0;
        for (const w of entries) {
            rx += w.rxBps;
            tx += w.txBps;
        }
        trafficHistory = trafficHistory.concat([{ rx: rx, tx: tx }]).slice(-historyLength);
    }
}
