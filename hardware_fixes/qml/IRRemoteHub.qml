import QtQuick 2.4
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: "irRemoteHub"
    applicationName: "sweet-ir-remote"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property string activeCategory: "tv"  // "tv" or "ac"
    property string activeDevice: "samsung_tv"
    property string lastKeySent: ""
    property bool txGlow: false
    property int acTemp: 24

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

    function sendIr(key) {
        lastKeySent = key;
        txGlow = true;
        txTimer.restart();
        apiPost("/api/ir/send?device=" + activeDevice + "&key=" + encodeURIComponent(key), function(res) {});
    }

    Timer {
        id: txTimer
        interval: 250
        running: false
        repeat: false
        onTriggered: txGlow = false
    }

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: "CyberNeon IR Remote"
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

                // Transmitter Status Banner
                Rectangle {
                    width: parent.width
                    height: units.gu(8)
                    radius: units.gu(1)
                    color: txGlow ? "#330022" : "#181a24"
                    border.color: txGlow ? "#ff007f" : "#2a2d3d"
                    border.width: 1

                    Row {
                        anchors.centerIn: parent
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: units.gu(2.5)
                            height: units.gu(2.5)
                            radius: width / 2
                            color: txGlow ? "#ff007f" : "#444455"
                            border.color: txGlow ? "#ffffff" : "#222233"
                            border.width: 1
                        }

                        Label {
                            anchors.verticalCenter: parent.verticalCenter
                            text: txGlow ? "TRANSMITTING: " + lastKeySent.toUpperCase() : "IR BLASTER READY (/dev/lirc0)"
                            color: txGlow ? "#ff007f" : "#888899"
                            font.bold: true
                            fontSize: "small"
                        }
                    }
                }

                // Category Tabs (TV / AC)
                Row {
                    width: parent.width
                    spacing: units.gu(1.5)

                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(5)
                        radius: units.gu(0.8)
                        color: activeCategory === "tv" ? "#00e5ff" : "#1f2230"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                activeCategory = "tv";
                                activeDevice = "samsung_tv";
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "📺 Smart TV"
                            color: activeCategory === "tv" ? "#000000" : "#ffffff"
                            font.bold: true
                        }
                    }

                    Rectangle {
                        width: (parent.width - units.gu(1.5)) / 2
                        height: units.gu(5)
                        radius: units.gu(0.8)
                        color: activeCategory === "ac" ? "#00e676" : "#1f2230"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                activeCategory = "ac";
                                activeDevice = "daikin_ac";
                            }
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "❄️ Air Conditioner"
                            color: activeCategory === "ac" ? "#000000" : "#ffffff"
                            font.bold: true
                        }
                    }
                }

                // Brand Selector Buttons
                Flow {
                    width: parent.width
                    spacing: units.gu(1)

                    Repeater {
                        model: activeCategory === "tv" ? [
                            { id: "samsung_tv", label: "Samsung" },
                            { id: "lg_tv", label: "LG" },
                            { id: "sony_tv", label: "Sony" },
                            { id: "xiaomi_tv", label: "Mi TV" }
                        ] : [
                            { id: "daikin_ac", label: "Daikin" },
                            { id: "gree_ac", label: "Gree" },
                            { id: "voltas_ac", label: "Voltas" },
                            { id: "aux_ac", label: "AUX" }
                        ]

                        Rectangle {
                            width: units.gu(9.5)
                            height: units.gu(4)
                            radius: units.gu(0.6)
                            color: activeDevice === modelData.id ? "#7c4dff" : "#1a1c28"
                            border.color: activeDevice === modelData.id ? "#00e5ff" : "#2a2d3d"
                            border.width: 1

                            MouseArea {
                                anchors.fill: parent
                                onClicked: activeDevice = modelData.id
                            }

                            Label {
                                anchors.centerIn: parent
                                text: modelData.label
                                color: "#ffffff"
                                fontSize: "small"
                                font.bold: activeDevice === modelData.id
                            }
                        }
                    }
                }

                // TV Controls View
                Column {
                    width: parent.width
                    spacing: units.gu(2)
                    visible: activeCategory === "tv"

                    // Power & Mute Row
                    Row {
                        width: parent.width
                        spacing: units.gu(2)

                        Rectangle {
                            width: (parent.width - units.gu(2)) / 2
                            height: units.gu(6)
                            radius: units.gu(1)
                            color: "#d50000"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: sendIr("power")
                            }

                            Label {
                                anchors.centerIn: parent
                                text: "⏻ POWER"
                                color: "#ffffff"
                                font.bold: true
                            }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(2)) / 2
                            height: units.gu(6)
                            radius: units.gu(1)
                            color: "#2a2d3d"

                            MouseArea {
                                anchors.fill: parent
                                onClicked: sendIr("mute")
                            }

                            Label {
                                anchors.centerIn: parent
                                text: "🔇 MUTE"
                                color: "#ffffff"
                                font.bold: true
                            }
                        }
                    }

                    // Rockers (Volume & Channel)
                    Row {
                        width: parent.width
                        spacing: units.gu(2)

                        // Volume Box
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 2
                            height: units.gu(16)
                            radius: units.gu(1)
                            color: "#181a24"
                            border.color: "#00e5ff"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: units.gu(1)
                                spacing: units.gu(1)

                                Rectangle {
                                    width: parent.width
                                    height: units.gu(5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea { anchors.fill: parent; onClicked: sendIr("vol_up") }
                                    Label { anchors.centerIn: parent; text: "VOL +"; color: "#00e5ff"; font.bold: true }
                                }

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "VOLUME"
                                    color: "#888899"
                                    fontSize: "small"
                                }

                                Rectangle {
                                    width: parent.width
                                    height: units.gu(5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea { anchors.fill: parent; onClicked: sendIr("vol_down") }
                                    Label { anchors.centerIn: parent; text: "VOL -"; color: "#00e5ff"; font.bold: true }
                                }
                            }
                        }

                        // Channel Box
                        Rectangle {
                            width: (parent.width - units.gu(2)) / 2
                            height: units.gu(16)
                            radius: units.gu(1)
                            color: "#181a24"
                            border.color: "#7c4dff"
                            border.width: 1

                            Column {
                                anchors.fill: parent
                                anchors.margins: units.gu(1)
                                spacing: units.gu(1)

                                Rectangle {
                                    width: parent.width
                                    height: units.gu(5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea { anchors.fill: parent; onClicked: sendIr("ch_up") }
                                    Label { anchors.centerIn: parent; text: "CH ▲"; color: "#7c4dff"; font.bold: true }
                                }

                                Label {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    text: "CHANNEL"
                                    color: "#888899"
                                    fontSize: "small"
                                }

                                Rectangle {
                                    width: parent.width
                                    height: units.gu(5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea { anchors.fill: parent; onClicked: sendIr("ch_down") }
                                    Label { anchors.centerIn: parent; text: "CH ▼"; color: "#7c4dff"; font.bold: true }
                                }
                            }
                        }
                    }

                    // Navigation D-Pad & Source
                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#1f2230"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("source") }
                            Label { anchors.centerIn: parent; text: "SOURCE"; color: "#ffffff"; fontSize: "small" }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#00e5ff"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("ok") }
                            Label { anchors.centerIn: parent; text: "OK / ENTER"; color: "#000000"; font.bold: true; fontSize: "small" }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#1f2230"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("menu") }
                            Label { anchors.centerIn: parent; text: "MENU"; color: "#ffffff"; fontSize: "small" }
                        }
                    }
                }

                // Air Conditioner Controls View
                Column {
                    width: parent.width
                    spacing: units.gu(2)
                    visible: activeCategory === "ac"

                    // AC Power Toggle
                    Rectangle {
                        width: parent.width
                        height: units.gu(6)
                        radius: units.gu(1)
                        color: "#00e676"

                        MouseArea {
                            anchors.fill: parent
                            onClicked: sendIr("power_toggle")
                        }

                        Label {
                            anchors.centerIn: parent
                            text: "❄️ AC POWER TOGGLE"
                            color: "#000000"
                            font.bold: true
                        }
                    }

                    // Temperature Display Card
                    Rectangle {
                        width: parent.width
                        height: units.gu(18)
                        radius: units.gu(1)
                        color: "#181a24"
                        border.color: "#00e676"
                        border.width: 1

                        Column {
                            anchors.centerIn: parent
                            spacing: units.gu(1)

                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: acTemp + "°C"
                                color: "#00e676"
                                font.bold: true
                                font.pixelSize: units.gu(5.5)
                            }

                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "TARGET COOLING TEMPERATURE"
                                color: "#888899"
                                fontSize: "small"
                            }

                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter
                                spacing: units.gu(3)

                                Rectangle {
                                    width: units.gu(8)
                                    height: units.gu(4.5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (acTemp > 16) acTemp -= 1;
                                            sendIr("temp_down");
                                        }
                                    }
                                    Label { anchors.centerIn: parent; text: "− 1°C"; color: "#00e5ff"; font.bold: true }
                                }

                                Rectangle {
                                    width: units.gu(8)
                                    height: units.gu(4.5)
                                    radius: units.gu(0.6)
                                    color: "#1f2230"
                                    MouseArea {
                                        anchors.fill: parent
                                        onClicked: {
                                            if (acTemp < 30) acTemp += 1;
                                            sendIr("temp_up");
                                        }
                                    }
                                    Label { anchors.centerIn: parent; text: "+ 1°C"; color: "#ff007f"; font.bold: true }
                                }
                            }
                        }
                    }

                    // AC Modes
                    Row {
                        width: parent.width
                        spacing: units.gu(1.5)

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#1f2230"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("mode_cool") }
                            Label { anchors.centerIn: parent; text: "COOL"; color: "#00e5ff"; fontSize: "small"; font.bold: true }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#1f2230"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("fan_speed") }
                            Label { anchors.centerIn: parent; text: "FAN SPEED"; color: "#ffffff"; fontSize: "small" }
                        }

                        Rectangle {
                            width: (parent.width - units.gu(3)) / 3
                            height: units.gu(5)
                            radius: units.gu(0.8)
                            color: "#1f2230"
                            MouseArea { anchors.fill: parent; onClicked: sendIr("mode_dry") }
                            Label { anchors.centerIn: parent; text: "DRY"; color: "#ff9100"; fontSize: "small" }
                        }
                    }
                }
            }
        }
    }
}
