import QtQuick 2.4
import Ubuntu.Components 1.3
import QtMultimedia 5.0

MainView {
    id: root
    objectName: "cameraStudio"
    applicationName: "sweet-camera-studio"

    width: units.gu(45)
    height: units.gu(100)
    backgroundColor: "#000000"

    property string apiBase: "http://127.0.0.1:8088"
    property string activeLensName: "main" // main, wide, macro, selfie
    property string activeMode: "PHOTO" // PHOTO, 108MP, VIDEO
    property string lastCapturedImage: ""
    property bool flashOn: false

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

    function switchLens(lens) {
        activeLensName = lens;
        apiPost("/api/camera/lens?lens=" + lens, function() {
            // Restart camera backend for new sensor
            camera.stop();
            camera.start();
        });
    }

    Camera {
        id: camera
        captureMode: Camera.CaptureStillImage

        imageCapture {
            onImageCaptured: {
                lastCapturedImage = preview;
            }
            onImageSaved: {
                lastCapturedImage = path;
            }
        }
    }

    Item {
        anchors.fill: parent

        // Viewfinder
        VideoOutput {
            id: viewfinder
            anchors.fill: parent
            source: camera
            fillMode: VideoOutput.PreserveAspectCrop
        }

        // Top Safe Zone / Punch-Hole Avoidance Margin (units.gu(5))
        Item {
            id: topControls
            anchors.top: parent.top
            anchors.topMargin: units.gu(5) // Punch-hole safe margin
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(6)

            Row {
                anchors.centerIn: parent
                spacing: units.gu(2)

                // Flash Button
                Rectangle {
                    width: units.gu(4.5)
                    height: units.gu(4.5)
                    radius: width / 2
                    color: "#66000000"
                    Label {
                        anchors.centerIn: parent
                        text: flashOn ? "⚡" : "🚫"
                        font.pixelSize: units.gu(2.2)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            flashOn = !flashOn;
                            camera.flash.mode = flashOn ? Camera.FlashOn : Camera.FlashOff;
                        }
                    }
                }

                // 108MP Ultra-HD Toggle Badge
                Rectangle {
                    width: units.gu(12)
                    height: units.gu(4.5)
                    radius: units.gu(1)
                    color: activeMode === "108MP" ? "#00e5ff" : "#66000000"
                    Label {
                        anchors.centerIn: parent
                        text: "108MP RAW"
                        color: activeMode === "108MP" ? "#000000" : "#ffffff"
                        font.bold: true
                        fontSize: "small"
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            activeMode = (activeMode === "108MP") ? "PHOTO" : "108MP";
                        }
                    }
                }

                // Active Lens Badge
                Rectangle {
                    height: units.gu(4.5)
                    width: units.gu(16)
                    radius: units.gu(1)
                    color: "#66000000"
                    Label {
                        anchors.centerIn: parent
                        text: activeLensName === "main" ? "Samsung 108MP" : (activeLensName === "wide" ? "8MP Ultra-Wide" : (activeLensName === "macro" ? "5MP Telemacro" : "16MP Selfie"))
                        color: "#00e5ff"
                        fontSize: "small"
                    }
                }
            }
        }

        // Bottom Controls Container
        Item {
            id: bottomControls
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: units.gu(22)

            // Lens Switcher Pill Bar (0.6x, 1x, 2x, Selfie)
            Rectangle {
                anchors.top: parent.top
                anchors.horizontalCenter: parent.horizontalCenter
                width: units.gu(32)
                height: units.gu(5)
                radius: units.gu(2.5)
                color: "#aa000000"

                Row {
                    anchors.centerIn: parent
                    spacing: units.gu(1)

                    // 0.6x Ultra-Wide
                    Rectangle {
                        width: units.gu(6.5)
                        height: units.gu(4)
                        radius: units.gu(2)
                        color: activeLensName === "wide" ? "#00e5ff" : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: "0.6x"
                            color: activeLensName === "wide" ? "#000000" : "#ffffff"
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: switchLens("wide")
                        }
                    }

                    // 1x Main 108MP
                    Rectangle {
                        width: units.gu(6.5)
                        height: units.gu(4)
                        radius: units.gu(2)
                        color: activeLensName === "main" ? "#00e5ff" : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: "1x"
                            color: activeLensName === "main" ? "#000000" : "#ffffff"
                            font.bold: true
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: switchLens("main")
                        }
                    }

                    // 2x Macro
                    Rectangle {
                        width: units.gu(6.5)
                        height: units.gu(4)
                        radius: units.gu(2)
                        color: activeLensName === "macro" ? "#00e5ff" : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: "Macro"
                            color: activeLensName === "macro" ? "#000000" : "#ffffff"
                            font.bold: true
                            fontSize: "small"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: switchLens("macro")
                        }
                    }

                    // Selfie
                    Rectangle {
                        width: units.gu(6.5)
                        height: units.gu(4)
                        radius: units.gu(2)
                        color: activeLensName === "selfie" ? "#00e5ff" : "transparent"
                        Label {
                            anchors.centerIn: parent
                            text: "🤳 Front"
                            color: activeLensName === "selfie" ? "#000000" : "#ffffff"
                            font.bold: true
                            fontSize: "small"
                        }
                        MouseArea {
                            anchors.fill: parent
                            onClicked: switchLens("selfie")
                        }
                    }
                }
            }

            // Shutter Button & Thumbnails
            Item {
                anchors.bottom: parent.bottom
                anchors.bottomMargin: units.gu(3)
                anchors.left: parent.left
                anchors.right: parent.right
                height: units.gu(10)

                // Gallery Thumbnail Preview (Left)
                Rectangle {
                    anchors.left: parent.left
                    anchors.leftMargin: units.gu(4)
                    anchors.verticalCenter: parent.verticalCenter
                    width: units.gu(6)
                    height: units.gu(6)
                    radius: units.gu(1)
                    color: "#333333"
                    clip: true

                    Image {
                        anchors.fill: parent
                        source: lastCapturedImage ? "file://" + lastCapturedImage : ""
                        fillMode: Image.PreserveAspectCrop
                        visible: lastCapturedImage !== ""
                    }
                    Label {
                        anchors.centerIn: parent
                        text: "🖼️"
                        visible: lastCapturedImage === ""
                        font.pixelSize: units.gu(2.5)
                    }
                }

                // Center Shutter Button
                Rectangle {
                    id: shutterOuter
                    anchors.centerIn: parent
                    width: units.gu(9)
                    height: units.gu(9)
                    radius: width / 2
                    color: "transparent"
                    border.color: "#ffffff"
                    border.width: units.gu(0.4)

                    Rectangle {
                        id: shutterInner
                        anchors.centerIn: parent
                        width: units.gu(7.2)
                        height: units.gu(7.2)
                        radius: width / 2
                        color: activeMode === "108MP" ? "#00e5ff" : "#ffffff"

                        MouseArea {
                            anchors.fill: parent
                            onPressed: shutterInner.scale = 0.88
                            onReleased: {
                                shutterInner.scale = 1.0;
                                camera.imageCapture.capture();
                            }
                        }
                    }
                }

                // Lens Flip Shortcut (Right)
                Rectangle {
                    anchors.right: parent.right
                    anchors.rightMargin: units.gu(4)
                    anchors.verticalCenter: parent.verticalCenter
                    width: units.gu(6)
                    height: units.gu(6)
                    radius: width / 2
                    color: "#aa000000"
                    Label {
                        anchors.centerIn: parent
                        text: "🔄"
                        font.pixelSize: units.gu(2.8)
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (activeLensName === "selfie") {
                                switchLens("main");
                            } else {
                                switchLens("selfie");
                            }
                        }
                    }
                }
            }
        }
    }
}
