import QtQuick 2.4
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: "batteryHub"
    applicationName: "sweet-battery-hub"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property int percentage: 85
    property string status: "Discharging"
    property int voltageMv: 4200
    property int currentMa: 0
    property real wattageW: 0.0
    property real tempC: 32.0
    property bool isFastCharge: false
    property string chargeSpeed: "Standard"
    property int healthPct: 98
    property string activeProfile: "balanced"

    function apiGet(path, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("GET", apiBase + path, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);
                    callback(data);
                } catch(e) {}
            }
        };
        xhr.send();
    }

    function apiPost(path, callback) {
        var xhr = new XMLHttpRequest();
        xhr.open("POST", apiBase + path, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                if (callback) {
                    try {
                        var data = JSON.parse(xhr.responseText);
                        callback(data);
                    } catch(e) {}
                }
            }
        };
        xhr.send();
    }

    function refresh() {
        apiGet("/api/battery/status", function(data) {
            percentage = data.percentage || 85;
            status = data.status || "Discharging";
            voltageMv = data.voltage_mv || 4200;
            currentMa = data.current_ma || 0;
            wattageW = data.wattage_w || 0.0;
            tempC = data.temp_c || 32.0;
            isFastCharge = data.is_fast_charge || false;
            chargeSpeed = data.charge_speed || "Standard";
            healthPct = data.health_pct || 98;
            activeProfile = data.profile || "balanced";
        });
    }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: "33W Power & Battery Studio"
            trailingActionBar.actions: [
                Action {
                    iconName: "reload"
                    text: "Refresh"
                    onTriggered: refresh()
                }
            ]
        }

        Flickable {
            anchors.top: pageHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            contentHeight: contentCol.height + units.gu(4)
            clip: true

            Column {
                id: contentCol
                width: parent.width
                spacing: units.gu(2)

                // Battery Status Card
                Rectangle {
                    width: parent.width
                    height: units.gu(22)
                    radius: units.gu(1.5)
                    color: "#181a24"
                    border.color: isFastCharge ? "#00e676" : (status === "Charging" ? "#00e5ff" : "#2d3248")
                    border.width: units.gu(0.3)

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.8)

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: percentage + "%"
                            color: percentage > 20 ? "#00e676" : "#ff1744"
                            font.bold: true
                            font.pixelSize: units.gu(6.5)
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: isFastCharge ? "⚡ 33W Mi Turbo Charge Active" : (status === "Charging" ? "⚡ Charging (" + wattageW + " W)" : "🔋 Discharging")
                            color: isFastCharge ? "#00e676" : "#ffffff"
                            font.bold: true
                            fontSize: "medium"
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: chargeSpeed
                            color: "#00e5ff"
                            fontSize: "small"
                        }
                    }
                }

                // Live Charging Telemetry Grid
                Rectangle {
                    width: parent.width
                    height: units.gu(18)
                    radius: units.gu(1)
                    color: "#181a24"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1)

                        Label {
                            text: "Live Power Telemetry"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Grid {
                            width: parent.width
                            columns: 2
                            rowSpacing: units.gu(1)
                            columnSpacing: units.gu(2)

                            Column {
                                Label { text: "Wattage:"; color: "#888899"; fontSize: "small" }
                                Label { text: wattageW + " W"; color: "#ffffff"; font.bold: true; fontSize: "medium" }
                            }

                            Column {
                                Label { text: "Voltage:"; color: "#888899"; fontSize: "small" }
                                Label { text: (voltageMv / 1000.0).toFixed(2) + " V"; color: "#ffffff"; font.bold: true; fontSize: "medium" }
                            }

                            Column {
                                Label { text: "Current Flow:"; color: "#888899"; fontSize: "small" }
                                Label { text: currentMa + " mA"; color: "#ffffff"; font.bold: true; fontSize: "medium" }
                            }

                            Column {
                                Label { text: "Battery Temp:"; color: "#888899"; fontSize: "small" }
                                Label { text: tempC + " °C"; color: tempC < 40 ? "#00e676" : "#ff9100"; font.bold: true; fontSize: "medium" }
                            }
                        }
                    }
                }

                // Power Governor Profiles
                Rectangle {
                    width: parent.width
                    height: units.gu(20)
                    radius: units.gu(1)
                    color: "#181a24"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1.2)

                        Label {
                            text: "CPU Power Governors"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1)

                            Button {
                                width: (parent.width - units.gu(2)) / 3
                                height: units.gu(5.5)
                                color: activeProfile === "performance" ? "#ff1744" : "#252836"
                                text: "Performance"
                                onClicked: {
                                    activeProfile = "performance";
                                    apiPost("/api/battery/profile?name=performance");
                                }
                            }

                            Button {
                                width: (parent.width - units.gu(2)) / 3
                                height: units.gu(5.5)
                                color: activeProfile === "balanced" ? "#00e5ff" : "#252836"
                                text: "Balanced"
                                onClicked: {
                                    activeProfile = "balanced";
                                    apiPost("/api/battery/profile?name=balanced");
                                }
                            }

                            Button {
                                width: (parent.width - units.gu(2)) / 3
                                height: units.gu(5.5)
                                color: activeProfile === "saver" ? "#00e676" : "#252836"
                                text: "Deep Saver"
                                onClicked: {
                                    activeProfile = "saver";
                                    apiPost("/api/battery/profile?name=saver");
                                }
                            }
                        }

                        Label {
                            text: activeProfile === "saver" ? "• Deep Saver: Cores 6&7 hot-unplugged, 300MHz C-state sleep (<0.8%/hr)" : (activeProfile === "performance" ? "• Performance: All 8 Kryo 470 cores active, maximum clock" : "• Balanced: Intelligent frequency scaling, standard Halium profile")
                            color: "#888899"
                            wrapMode: Text.WordWrap
                            width: parent.width
                            fontSize: "small"
                        }
                    }
                }
            }
        }
    }
}
