import QtQuick 2.4
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: "controlCenter"
    applicationName: "sweet-control-center"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property int fpsVal: 120
    property int battPct: 85
    property real battWatt: 0.0
    property bool fastChargeActive: false
    property int fpCount: 0
    property bool volteActive: true

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

    function refreshAll() {
        apiGet("/api/display/status", function(d) { fpsVal = d.fps || 120; });
        apiGet("/api/battery/status", function(d) {
            battPct = d.percentage || 85;
            battWatt = d.wattage_w || 0.0;
            fastChargeActive = d.is_fast_charge || false;
        });
        apiGet("/api/fingerprint/status", function(d) {
            fpCount = (d.fingerprints || []).length;
        });
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        onTriggered: refreshAll()
    }

    Component.onCompleted: refreshAll()

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: "SweetLinux Control Center"
            trailingActionBar.actions: [
                Action {
                    iconName: "reload"
                    text: "Refresh"
                    onTriggered: refreshAll()
                }
            ]
        }

        Flickable {
            anchors.top: pageHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            contentHeight: col.height + units.gu(4)
            clip: true

            Column {
                id: col
                width: parent.width
                spacing: units.gu(1.8)

                // Device Banner
                Rectangle {
                    width: parent.width
                    height: units.gu(9)
                    radius: units.gu(1)
                    color: "#181a24"
                    border.color: "#00e5ff"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.2)
                        spacing: units.gu(0.4)

                        Label {
                            text: "Redmi Note 10 Pro / Pro Max (sweet)"
                            color: "#ffffff"
                            font.bold: true
                            fontSize: "medium"
                        }
                        Label {
                            text: "Qualcomm Snapdragon 732G • CyberNeon v1.0 • Focal 20.04"
                            color: "#00e5ff"
                            fontSize: "small"
                        }
                    }
                }

                // Subsystems Grid
                Grid {
                    width: parent.width
                    columns: 2
                    rowSpacing: units.gu(1.5)
                    columnSpacing: units.gu(1.5)

                    // 1. Display Hub Card
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(15)
                        radius: units.gu(1)
                        color: "#1f2230"

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(0.8)

                            Label { text: "🖥️ Display"; color: "#00e5ff"; font.bold: true }
                            Label { text: fpsVal + " Hz"; color: "#ffffff"; font.bold: true; font.pixelSize: units.gu(3.5) }
                            Label { text: "Huaxing LCD (120/60)"; color: "#888899"; fontSize: "small" }
                        }
                    }

                    // 2. Battery Hub Card
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(15)
                        radius: units.gu(1)
                        color: "#1f2230"

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(0.8)

                            Label { text: "⚡ 33W Power"; color: "#00e676"; font.bold: true }
                            Label { text: battPct + "%"; color: "#ffffff"; font.bold: true; font.pixelSize: units.gu(3.5) }
                            Label { text: fastChargeActive ? "33W Turbo Active" : "Discharging"; color: "#888899"; fontSize: "small" }
                        }
                    }

                    // 3. Biometrics Card
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(15)
                        radius: units.gu(1)
                        color: "#1f2230"

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(0.8)

                            Label { text: "🔒 Fingerprint"; color: "#7b1fa2"; font.bold: true }
                            Label { text: fpCount + " Saved"; color: "#ffffff"; font.bold: true; font.pixelSize: units.gu(3) }
                            Label { text: "FPC Sensor Ready"; color: "#888899"; fontSize: "small" }
                        }
                    }

                    // 4. VoLTE Card
                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(15)
                        radius: units.gu(1)
                        color: "#1f2230"

                        Column {
                            anchors.fill: parent
                            anchors.margins: units.gu(1.5)
                            spacing: units.gu(0.8)

                            Label { text: "📶 VoLTE IMS"; color: "#ff9100"; font.bold: true }
                            Label { text: "Active"; color: "#00e676"; font.bold: true; font.pixelSize: units.gu(3) }
                            Label { text: "Dual-SIM VoLTE HD"; color: "#888899"; fontSize: "small" }
                        }
                    }
                }

                // Dedicated Hub Launchers
                Label {
                    text: "Hardware Subsystem Managers"
                    color: "#00e5ff"
                    font.bold: true
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#00e5ff"
                    text: "🔒 Launch Biometric Fingerprint Hub"
                    onClicked: {
                        // Launch script
                    }
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#2979ff"
                    text: "🖥️ Launch Display & 120Hz/60Hz Hub"
                    onClicked: {}
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#00e676"
                    text: "⚡ Launch 33W Fast Charge & Battery Studio"
                    onClicked: {}
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#7b1fa2"
                    text: "📷 Launch 108MP Pro Camera Studio"
                    onClicked: {}
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#ff9100"
                    text: "📶 Launch VoLTE Carrier Diagnostics Hub"
                    onClicked: {}
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#00e676"
                    text: "🛡️ Launch Play Integrity & Android Hub"
                    onClicked: {}
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#ff007f"
                    text: "📡 Launch CyberNeon IR Remote Blaster Hub"
                    onClicked: {}
                }
            }
        }
    }
}
