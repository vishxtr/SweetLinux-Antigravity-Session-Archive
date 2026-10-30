import QtQuick 2.4
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: "displayHub"
    applicationName: "sweet-display-hub"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property int currentFps: 120
    property int brightnessVal: 1024
    property bool dynamicFps: true
    property bool punchholeSafe: true
    property bool autoRotate: true
    property string orientationMode: "portrait"
    property string panelVendor: "Samsung Super AMOLED (dsi_k6_38_0c_0a_fhd_dsc_video)"

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
        apiGet("/api/display/status", function(data) {
            currentFps = data.fps || 120;
            brightnessVal = data.brightness || 1024;
            dynamicFps = data.dynamic_fps;
            punchholeSafe = data.punchhole_safe;
            if (data.panel_vendor) panelVendor = data.panel_vendor;
        });
        apiGet("/api/sensors/status", function(s) {
            if (s && s.rotation) {
                autoRotate = s.rotation.auto_rotate;
                orientationMode = s.rotation.orientation;
            }
        });
    }

    Timer {
        interval: 3000
        running: true
        repeat: true
        onTriggered: refresh()
    }

    Component.onCompleted: refresh()

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: "Display & Refresh Rate Hub"
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

                // Big FPS Speedometer Card
                Rectangle {
                    width: parent.width
                    height: units.gu(18)
                    radius: units.gu(1.5)
                    color: "#181a24"
                    border.color: currentFps === 120 ? "#00e5ff" : "#ffb300"
                    border.width: units.gu(0.3)

                    Column {
                        anchors.centerIn: parent
                        spacing: units.gu(0.5)

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: currentFps + " Hz"
                            color: currentFps === 120 ? "#00e5ff" : "#ffb300"
                            font.bold: true
                            font.pixelSize: units.gu(6)
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: currentFps === 120 ? "⚡ Ultra-Smooth 120Hz Active" : "🔋 60Hz Power Saver Mode"
                            color: "#ffffff"
                            font.bold: true
                        }

                        Label {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: "1080 × 2400 @ " + currentFps + "Hz | MIPI-DSI Video Mode"
                            color: "#888899"
                            fontSize: "small"
                        }
                    }
                }

                // Refresh Rate Switch Buttons
                Row {
                    width: parent.width
                    spacing: units.gu(1.5)

                    Button {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(6)
                        color: currentFps === 60 ? "#ffb300" : "#252836"
                        text: "60 Hz (Standard)"
                        onClicked: {
                            currentFps = 60;
                            apiPost("/api/display/set?fps=60", function() { refresh(); });
                        }
                    }

                    Button {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(6)
                        color: currentFps === 120 ? "#00e5ff" : "#252836"
                        text: "120 Hz (Ultra)"
                        onClicked: {
                            currentFps = 120;
                            apiPost("/api/display/set?fps=120", function() { refresh(); });
                        }
                    }
                }

                // Feature Options Card
                Rectangle {
                    width: parent.width
                    height: units.gu(22)
                    radius: units.gu(1)
                    color: "#181a24"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1.5)

                        Label {
                            text: "Display Enhancements"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        // Punchhole Toggle
                        Row {
                            width: parent.width
                            Column {
                                width: parent.width - punchSwitch.width
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    text: "Punch-Hole Cutout Protection"
                                    color: "#ffffff"
                                    font.bold: true
                                }
                                Label {
                                    text: "Adds symmetrical top margin to avoid camera hole"
                                    color: "#777788"
                                    fontSize: "small"
                                }
                            }
                            Switch {
                                id: punchSwitch
                                checked: punchholeSafe
                                onCheckedChanged: {
                                    punchholeSafe = checked;
                                    apiPost("/api/display/punchhole?enabled=" + checked);
                                }
                            }
                        }

                        // Dynamic FPS Toggle
                        Row {
                            width: parent.width
                            Column {
                                width: parent.width - dynSwitch.width
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    text: "Dynamic Auto-Refresh"
                                    color: "#ffffff"
                                    font.bold: true
                                }
                                Label {
                                    text: "60Hz when idle/low battery, 120Hz on interaction"
                                    color: "#777788"
                                    fontSize: "small"
                                }
                            }
                            Switch {
                                id: dynSwitch
                                checked: dynamicFps
                                onCheckedChanged: {
                                    dynamicFps = checked;
                                    apiPost("/api/display/dynamic?enabled=" + checked);
                                }
                            }
                        }
                    }
                }

                // Auto-Rotation & Motion Sensors Card
                Rectangle {
                    width: parent.width
                    height: units.gu(26)
                    radius: units.gu(1)
                    color: "#181a24"
                    border.color: "#7c4dff"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1.2)

                        Label {
                            text: "🔄 Orientation & Motion Sensors"
                            color: "#7c4dff"
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            Column {
                                width: parent.width - rotSwitch.width
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    text: "Auto-Rotate Screen"
                                    color: "#ffffff"
                                    font.bold: true
                                }
                                Label {
                                    text: "STMicro LSM6DSO IMU + Qualcomm SLPI"
                                    color: "#777788"
                                    fontSize: "small"
                                }
                            }
                            Switch {
                                id: rotSwitch
                                checked: autoRotate
                                onCheckedChanged: {
                                    autoRotate = checked;
                                    apiPost("/api/sensors/orientation?mode=" + (checked ? "auto" : "portrait"));
                                }
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1.5)

                            Button {
                                width: (parent.width - units.gu(1.5)) / 2
                                height: units.gu(4.5)
                                color: orientationMode === "portrait" ? "#7c4dff" : "#1f2230"
                                text: "📱 Portrait"
                                onClicked: {
                                    orientationMode = "portrait";
                                    apiPost("/api/sensors/orientation?mode=portrait");
                                }
                            }

                            Button {
                                width: (parent.width - units.gu(1.5)) / 2
                                height: units.gu(4.5)
                                color: orientationMode === "landscape" ? "#7c4dff" : "#1f2230"
                                text: "🖥️ Landscape"
                                onClicked: {
                                    orientationMode = "landscape";
                                    apiPost("/api/sensors/orientation?mode=landscape");
                                }
                            }
                        }

                        Label {
                            text: "• Gyroscope: STMicro LSM6DSO 416Hz (Active)
• Proximity: Xiaomi Ultrasonic/Optical (Active)
• Ambient Light: Rohm BU27030 (Auto-Lux Active)"
                            color: "#00e5ff"
                            fontSize: "small"
                        }
                    }
                }

                // Hardware Hardware Specs Card
                Rectangle {
                    width: parent.width
                    height: units.gu(14)
                    radius: units.gu(1)
                    color: "#181a24"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(0.8)

                        Label {
                            text: "Display Hardware Specifications"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Label {
                            text: "• Panel: Huaxing Replacement FHD+ LCD"
                            color: "#bbbbcc"
                            fontSize: "small"
                        }
                        Label {
                            text: "• Resolution: 1080 × 2400 (20:9 Aspect Ratio, 395 PPI)"
                            color: "#bbbbcc"
                            fontSize: "small"
                        }
                        Label {
                            text: "• Backlight: MIPI DCS 11-bit Hardware PWM (0-2047)"
                            color: "#bbbbcc"
                            fontSize: "small"
                        }
                    }
                }
            }
        }
    }
}
