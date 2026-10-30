import QtQuick 2.4
import Ubuntu.Components 1.3

MainView {
    id: root
    objectName: "playIntegrityHub"
    applicationName: "sweet-play-integrity"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property string basicStatus: "PASS"
    property string deviceStatus: "PASS"
    property string strongStatus: "HARDWARE_LOCKED"
    property string modelName: "Pixel 7 Pro (cheetah)"
    property string fingerprintStr: "google/cheetah/cheetah:13/TQ3A.230901.001/10750766:user/release-keys"
    property string patchDate: "2023-09-05"
    property string modPathInput: "/home/phablet/Downloads/module.zip"
    property string convertLog: ""

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
        apiGet("/api/integrity/status", function(data) {
            if (data.basic_integrity) basicStatus = data.basic_integrity;
            if (data.device_integrity) deviceStatus = data.device_integrity;
            if (data.active_profile) {
                modelName = data.active_profile.MODEL + " (" + data.active_profile.DEVICE + ")";
                fingerprintStr = data.active_profile.FINGERPRINT;
                patchDate = data.active_profile.SECURITY_PATCH;
            }
        });
    }

    Component.onCompleted: refresh()

    Page {
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: "Play Integrity & Android Hub"
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
                spacing: units.gu(1.8)

                // Play Integrity Status Banner Card
                Rectangle {
                    width: parent.width
                    height: units.gu(19)
                    radius: units.gu(1.5)
                    color: "#181a24"
                    border.color: "#00e5ff"
                    border.width: units.gu(0.2)

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1)

                        Label {
                            text: "Play Integrity Attestation Verdicts"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1)
                            Rectangle {
                                width: units.gu(2)
                                height: units.gu(2)
                                radius: width / 2
                                color: "#00e676"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: "MEETS_BASIC_INTEGRITY: " + basicStatus
                                color: "#ffffff"
                                font.bold: true
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1)
                            Rectangle {
                                width: units.gu(2)
                                height: units.gu(2)
                                radius: width / 2
                                color: "#00e676"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: "MEETS_DEVICE_INTEGRITY: " + deviceStatus
                                color: "#ffffff"
                                font.bold: true
                            }
                        }

                        Row {
                            width: parent.width
                            spacing: units.gu(1)
                            Rectangle {
                                width: units.gu(2)
                                height: units.gu(2)
                                radius: width / 2
                                color: "#ff9100"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: "MEETS_STRONG_INTEGRITY: BLOCKED (Unlocked Bootloader)"
                                color: "#ff9100"
                                fontSize: "small"
                            }
                        }
                    }
                }

                // Active Certified Profile Card
                Rectangle {
                    width: parent.width
                    height: units.gu(16)
                    radius: units.gu(1)
                    color: "#1f2230"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(0.6)

                        Label {
                            text: "Active Certified Attestation Profile"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Label {
                            text: "Device: " + modelName
                            color: "#ffffff"
                            font.bold: true
                        }

                        Label {
                            text: "Fingerprint: " + fingerprintStr.substring(0, 36) + "..."
                            color: "#888899"
                            fontSize: "small"
                        }

                        Label {
                            text: "Security Patch: " + patchDate + " | First API: 25 (Keybox Downgrade)"
                            color: "#00e676"
                            fontSize: "small"
                        }

                        Button {
                            width: parent.width
                            height: units.gu(4.5)
                            color: "#2979ff"
                            text: "🔄 Regenerate Certified Profile"
                            onClicked: {
                                apiPost("/api/integrity/update_fingerprint", function() { refresh(); });
                            }
                        }
                    }
                }

                // Magisk & Zygisk Runtime Card
                Rectangle {
                    width: parent.width
                    height: units.gu(15)
                    radius: units.gu(1)
                    color: "#1f2230"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(0.8)

                        Label {
                            text: "Waydroid Magisk & Zygisk Runtime"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Label {
                            text: "• Magisk Core: v27.0 (Injected via Magiskinit)"
                            color: "#bbbbcc"
                        }
                        Label {
                            text: "• Zygisk Engine: Active & Enforcing DenyList"
                            color: "#00e676"
                        }
                        Label {
                            text: "• Active Modules: PlayIntegrityFix v17.2, Shamiko v1.1.1"
                            color: "#bbbbcc"
                        }
                    }
                }

                // Magisk Module Converter Card
                Rectangle {
                    width: parent.width
                    height: units.gu(20)
                    radius: units.gu(1)
                    color: "#181a24"

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(1)

                        Label {
                            text: "Magisk Module Converter & Installer"
                            color: "#00e5ff"
                            font.bold: true
                        }

                        Label {
                            text: "Converts any standard Magisk .zip module for Waydroid or Native Linux"
                            color: "#888899"
                            fontSize: "small"
                        }

                        TextField {
                            id: zipInput
                            width: parent.width
                            text: modPathInput
                            placeholderText: "Path to module.zip (e.g. /home/phablet/Downloads/...)"
                            onTextChanged: modPathInput = text
                        }

                        Button {
                            width: parent.width
                            height: units.gu(5)
                            color: "#7b1fa2"
                            text: "⚡ Convert & Install Magisk Module"
                            onClicked: {
                                convertLog = "Analyzing module: " + modPathInput + "...";
                                apiPost("/api/integrity/convert_module?path=" + encodeURIComponent(modPathInput), function(res) {
                                    convertLog = res.log || "Module successfully converted and deployed!";
                                    refresh();
                                });
                            }
                        }

                        Label {
                            text: convertLog ? convertLog : "Zygisk/Framework modules -> Waydroid | Kernel/Sysfs -> Native Linux"
                            color: convertLog ? "#00e676" : "#777788"
                            fontSize: "small"
                            wrapMode: Text.WordWrap
                            width: parent.width
                        }
                    }
                }
            }
        }
    }
}
