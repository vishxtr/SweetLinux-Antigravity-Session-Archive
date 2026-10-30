import QtQuick 2.4
import Ubuntu.Components 1.3
import Ubuntu.Components.Popups 1.3

MainView {
    id: root
    objectName: "fingerprintManager"
    applicationName: "sweet-fingerprint-manager"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#0d0e15"

    property string apiBase: "http://127.0.0.1:8088"
    property var fingerprintsList: []
    property bool fpEnabled: true
    property bool hapticsEnabled: true
    property string activeView: "LIST" // LIST, ENROLL, VERIFY

    // Enrollment properties
    property int enrollStep: 0
    property int enrollProgress: 0
    property string enrollPrompt: "Place finger on the side power button sensor"
    property bool enrollComplete: false
    property string newFingerName: "Right Thumb"

    // Verification properties
    property string verifyStatus: "Sensor ready. Touch with any enrolled finger."
    property string verifyName: ""
    property int verifyScore: 0
    property bool verifySuccess: false

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

    function refreshStatus() {
        apiGet("/api/fingerprint/status", function(data) {
            fingerprintsList = data.fingerprints || [];
            if (data.config) {
                fpEnabled = data.config.enabled;
                hapticsEnabled = data.config.haptics;
            }
        });
    }

    Timer {
        id: refreshTimer
        interval: 3000
        running: activeView === "LIST"
        repeat: true
        onTriggered: refreshStatus()
    }

    Timer {
        id: pollEnrollTimer
        interval: 200
        running: activeView === "ENROLL" && !enrollComplete
        repeat: true
        onTriggered: {
            apiGet("/api/fingerprint/enroll/poll", function(data) {
                enrollStep = data.step;
                enrollProgress = data.progress;
                enrollPrompt = data.prompt;
                if (data.complete) {
                    enrollComplete = true;
                    refreshStatus();
                }
            });
        }
    }

    Timer {
        id: pollVerifyTimer
        interval: 250
        running: activeView === "VERIFY"
        repeat: true
        onTriggered: {
            apiGet("/api/fingerprint/verify/poll", function(data) {
                if (data.result && data.result.timestamp) {
                    verifySuccess = data.result.matched;
                    verifyName = data.result.name;
                    verifyScore = data.result.score;
                    if (verifySuccess) {
                        verifyStatus = "MATCHED: " + verifyName + " (" + verifyScore + "% match)";
                    } else {
                        verifyStatus = "NOT RECOGNIZED: Please try again";
                    }
                }
            });
        }
    }

    Component.onCompleted: {
        refreshStatus();
    }

    Page {
        id: mainPage
        anchors.fill: parent

        header: PageHeader {
            id: pageHeader
            title: activeView === "ENROLL" ? "Register Fingerprint" : (activeView === "VERIFY" ? "Test Verification" : "Biometric Security")
            trailingActionBar.actions: [
                Action {
                    iconName: "reload"
                    text: "Refresh"
                    visible: activeView === "LIST"
                    onTriggered: refreshStatus()
                }
            ]
            leadingActionBar.actions: [
                Action {
                    iconName: "back"
                    text: "Back"
                    visible: activeView !== "LIST"
                    onTriggered: {
                        if (activeView === "ENROLL") {
                            apiPost("/api/fingerprint/enroll/cancel");
                        } else if (activeView === "VERIFY") {
                            apiPost("/api/fingerprint/verify/stop");
                        }
                        activeView = "LIST";
                        refreshStatus();
                    }
                }
            ]
        }

        // ==================== LIST / MANAGEMENT VIEW ====================
        Item {
            anchors.top: pageHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            visible: activeView === "LIST"

            Column {
                anchors.fill: parent
                spacing: units.gu(1.5)

                // Status Card
                Rectangle {
                    width: parent.width
                    height: units.gu(11)
                    color: "#181a24"
                    radius: units.gu(1)
                    border.color: "#00e5ff"
                    border.width: 1

                    Column {
                        anchors.fill: parent
                        anchors.margins: units.gu(1.5)
                        spacing: units.gu(0.8)

                        Row {
                            width: parent.width
                            spacing: units.gu(1)
                            Rectangle {
                                width: units.gu(1.5)
                                height: units.gu(1.5)
                                radius: width / 2
                                color: "#00e676"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Label {
                                text: "FPC Side-Mounted Sensor Active"
                                color: "#ffffff"
                                font.bold: true
                                fontSize: "medium"
                            }
                        }

                        Row {
                            width: parent.width
                            Label {
                                text: "Fingerprint Screen Unlock"
                                color: "#bbbbbb"
                                width: parent.width - toggleSwitch.width
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Switch {
                                id: toggleSwitch
                                checked: fpEnabled
                                onCheckedChanged: {
                                    fpEnabled = checked;
                                    apiPost("/api/fingerprint/toggle?key=unlock_screen&val=" + checked);
                                }
                            }
                        }
                    }
                }

                // Section Label
                Label {
                    text: "Registered Profiles (" + fingerprintsList.length + "/5)"
                    color: "#00e5ff"
                    font.bold: true
                }

                // Fingers List
                ListView {
                    id: fpListView
                    width: parent.width
                    height: units.gu(24)
                    clip: true
                    model: fingerprintsList
                    spacing: units.gu(1)

                    delegate: Rectangle {
                        width: fpListView.width
                        height: units.gu(7)
                        color: "#1f2230"
                        radius: units.gu(0.8)

                        Row {
                            anchors.fill: parent
                            anchors.margins: units.gu(1)
                            spacing: units.gu(1.5)

                            Rectangle {
                                width: units.gu(5)
                                height: units.gu(5)
                                radius: units.gu(0.5)
                                color: "#2d3248"
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    anchors.centerIn: parent
                                    text: "👆"
                                    font.pixelSize: units.gu(2.5)
                                }
                            }

                            Column {
                                width: parent.width - units.gu(14)
                                anchors.verticalCenter: parent.verticalCenter
                                Label {
                                    text: modelData.name || "Fingerprint"
                                    color: "#ffffff"
                                    font.bold: true
                                }
                                Label {
                                    text: "Enrolled: " + (modelData.enrolled_at || "Active")
                                    color: "#888899"
                                    fontSize: "small"
                                }
                            }

                            Button {
                                text: "Delete"
                                color: "#d32f2f"
                                width: units.gu(7)
                                height: units.gu(4)
                                anchors.verticalCenter: parent.verticalCenter
                                onClicked: {
                                    apiPost("/api/fingerprint/delete?id=" + modelData.id, function() {
                                        refreshStatus();
                                    });
                                }
                            }
                        }
                    }

                    // Empty State
                    Rectangle {
                        anchors.fill: parent
                        color: "transparent"
                        visible: fingerprintsList.length === 0
                        Column {
                            anchors.centerIn: parent
                            spacing: units.gu(1)
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "No fingerprints enrolled yet"
                                color: "#777788"
                            }
                            Label {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: "Tap below to begin registration"
                                color: "#555566"
                                fontSize: "small"
                            }
                        }
                    }
                }

                // Action Buttons
                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#00e5ff"
                    text: "➕ Register New Fingerprint"
                    onClicked: {
                        enrollStep = 0;
                        enrollProgress = 0;
                        enrollComplete = false;
                        enrollPrompt = "Place finger on the side sensor";
                        newFingerName = "Finger " + (fingerprintsList.length + 1);
                        apiPost("/api/fingerprint/enroll/start?name=" + encodeURIComponent(newFingerName));
                        activeView = "ENROLL";
                    }
                }

                Button {
                    width: parent.width
                    height: units.gu(5.5)
                    color: "#7b1fa2"
                    text: "🔍 Test Sensor & Verify Match"
                    onClicked: {
                        verifyStatus = "Sensor ready. Touch with any enrolled finger.";
                        verifyName = "";
                        verifyScore = 0;
                        verifySuccess = false;
                        apiPost("/api/fingerprint/verify/start");
                        activeView = "VERIFY";
                    }
                }
            }
        }

        // ==================== ENROLLMENT WIZARD VIEW ====================
        Item {
            anchors.top: pageHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            visible: activeView === "ENROLL"

            Column {
                anchors.centerIn: parent
                spacing: units.gu(2)
                width: parent.width

                // Fingerprint Visual Target
                Rectangle {
                    width: units.gu(16)
                    height: units.gu(16)
                    radius: width / 2
                    color: "#181a24"
                    border.color: enrollComplete ? "#00e676" : "#00e5ff"
                    border.width: units.gu(0.4)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        anchors.centerIn: parent
                        text: enrollComplete ? "✅" : "👆"
                        font.pixelSize: units.gu(6)
                    }
                }

                // Progress Percentage
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: enrollProgress + "%"
                    color: enrollComplete ? "#00e676" : "#00e5ff"
                    font.bold: true
                    fontSize: "x-large"
                }

                // Progress Bar
                ProgressBar {
                    width: parent.width * 0.8
                    height: units.gu(1.2)
                    anchors.horizontalCenter: parent.horizontalCenter
                    minimumValue: 0
                    maximumValue: 100
                    value: enrollProgress
                }

                // Instruction Prompt
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.85
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: enrollPrompt
                    color: "#ffffff"
                    font.bold: true
                    fontSize: "large"
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Step " + enrollStep + " of 5: Lift and press side sensor"
                    color: "#888899"
                    visible: !enrollComplete
                }

                // Finger Name Input when complete
                Column {
                    width: parent.width * 0.85
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: units.gu(1)
                    visible: enrollComplete

                    Label {
                        text: "Fingerprint Profile Name:"
                        color: "#00e676"
                        font.bold: true
                    }

                    TextField {
                        id: nameInput
                        width: parent.width
                        text: newFingerName
                        onTextChanged: newFingerName = text
                    }

                    Button {
                        width: parent.width
                        height: units.gu(5)
                        color: "#00e676"
                        text: "Save & Finish"
                        onClicked: {
                            activeView = "LIST";
                            refreshStatus();
                        }
                    }
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.6
                    height: units.gu(4.5)
                    color: "#444455"
                    text: "Cancel"
                    visible: !enrollComplete
                    onClicked: {
                        apiPost("/api/fingerprint/enroll/cancel");
                        activeView = "LIST";
                        refreshStatus();
                    }
                }
            }
        }

        // ==================== VERIFICATION TEST VIEW ====================
        Item {
            anchors.top: pageHeader.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.margins: units.gu(2)
            visible: activeView === "VERIFY"

            Column {
                anchors.centerIn: parent
                spacing: units.gu(2.5)
                width: parent.width

                Rectangle {
                    width: units.gu(16)
                    height: units.gu(16)
                    radius: width / 2
                    color: "#181a24"
                    border.color: verifyName ? (verifySuccess ? "#00e676" : "#ff1744") : "#7b1fa2"
                    border.width: units.gu(0.4)
                    anchors.horizontalCenter: parent.horizontalCenter

                    Label {
                        anchors.centerIn: parent
                        text: verifyName ? (verifySuccess ? "🔓" : "❌") : "🔍"
                        font.pixelSize: units.gu(6)
                    }
                }

                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.85
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    text: verifyStatus
                    color: verifySuccess ? "#00e676" : (verifyName ? "#ff1744" : "#ffffff")
                    font.bold: true
                    fontSize: "large"
                }

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width * 0.6
                    height: units.gu(4.5)
                    color: "#00e5ff"
                    text: "Done"
                    onClicked: {
                        apiPost("/api/fingerprint/verify/stop");
                        activeView = "LIST";
                        refreshStatus();
                    }
                }
            }
        }
    }
}
