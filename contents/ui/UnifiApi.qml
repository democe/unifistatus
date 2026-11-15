import QtQuick

// Minimal read-only client for the UniFi console.
// Integration API: <console>/proxy/network/integration/v1/   Auth: X-API-KEY header.
// Legacy API:      <console>/proxy/network/api/              Same header, used only for ISP/WAN health.
QtObject {
    id: api

    property string baseUrl: ""
    property string apiKey: ""

    readonly property int pageSize: 200

    function request(url, onOk, onErr) {
        const xhr = new XMLHttpRequest();
        xhr.open("GET", url);
        xhr.timeout = 10000;
        xhr.setRequestHeader("X-API-KEY", apiKey);
        xhr.setRequestHeader("Accept", "application/json");
        xhr.onreadystatechange = function () {
            if (xhr.readyState !== XMLHttpRequest.DONE)
                return;
            if (xhr.status >= 200 && xhr.status < 300) {
                try {
                    onOk(JSON.parse(xhr.responseText));
                } catch (e) {
                    onErr(i18n("Unexpected response"));
                }
            } else if (xhr.status === 401 || xhr.status === 403) {
                onErr(i18n("Invalid API key"));
            } else if (xhr.status === 0) {
                onErr(i18n("Console unreachable"));
            } else {
                onErr(i18n("HTTP %1", xhr.status));
            }
        };
        xhr.send();
    }

    function query(params) {
        return params ? "?" + Object.keys(params)
            .map(k => encodeURIComponent(k) + "=" + encodeURIComponent(params[k]))
            .join("&") : "";
    }

    function get(path, params, onOk, onErr) {
        request(baseUrl.replace(/\/+$/, "") + "/proxy/network/integration/v1/" + path + query(params), onOk, onErr);
    }

    function legacy(path, onOk, onErr) {
        request(baseUrl.replace(/\/+$/, "") + "/proxy/network/api/" + path, onOk, onErr);
    }

    // Collects every page of a list endpoint (offset/limit, count/totalCount).
    function all(path, onOk, onErr) {
        let items = [];
        function page(offset) {
            get(path, { offset: offset, limit: pageSize }, r => {
                const data = r.data ?? [];
                items = items.concat(data);
                if (data.length > 0 && items.length < r.totalCount)
                    page(offset + data.length);
                else
                    onOk(items);
            }, onErr);
        }
        page(0);
    }
}
