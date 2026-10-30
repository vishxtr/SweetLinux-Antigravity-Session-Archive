#!/bin/bash
set -e

echo "============================================================"
echo " SweetLinux v1.3 Master Hardware Subsystems & Suite Installer"
echo " Target: Xiaomi Redmi Note 10 Pro / Pro Max (sweet/sweetin)"
echo " Subsystems: Biometrics, 120Hz, Audio/Mic, Camera, VoLTE,"
echo "             Rotation IMU, Gyroscope, Proximity, IR Blaster,"
echo "             USB OTG Manager, Physical Buttons, OTA Updater"
echo "============================================================"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DEST_DIR="${1:-/}"
cd "$SCRIPT_DIR"
echo "[*] Target RootFS: ${DEST_DIR}"

# 1. Binaries
mkdir -p "${DEST_DIR}/usr/local/bin"
cp -v bin/* "${DEST_DIR}/usr/local/bin/"
chmod 755 "${DEST_DIR}/usr/local/bin/"sweet-*

# 2. QML Interfaces
mkdir -p "${DEST_DIR}/usr/share/sweetlinux/qml"
cp -v qml/* "${DEST_DIR}/usr/share/sweetlinux/qml/"
chmod 644 "${DEST_DIR}/usr/share/sweetlinux/qml/"*.qml

# 3. Desktop Application Launchers
mkdir -p "${DEST_DIR}/usr/share/applications"
cp -v desktop/* "${DEST_DIR}/usr/share/applications/"
chmod 644 "${DEST_DIR}/usr/share/applications/"*.desktop

# 4. Vector SVG Icons
mkdir -p "${DEST_DIR}/usr/share/pixmaps"
cp -v pixmaps/* "${DEST_DIR}/usr/share/pixmaps/"
chmod 644 "${DEST_DIR}/usr/share/pixmaps/"*.svg

# 5. Systemd Services
mkdir -p "${DEST_DIR}/etc/systemd/system"
cp -v systemd/* "${DEST_DIR}/etc/systemd/system/"
chmod 644 "${DEST_DIR}/etc/systemd/system/"*.service

# 6. Sensorfw Calibration & Orientation
if [ -d "sensorfw" ]; then
    mkdir -p "${DEST_DIR}/etc/sensorfw/sensord.conf.d"
    cp -v sensorfw/* "${DEST_DIR}/etc/sensorfw/sensord.conf.d/"
    chmod 644 "${DEST_DIR}/etc/sensorfw/sensord.conf.d/"*.conf
fi

# 7. Udev Hardware Rules
if [ -d "udev" ]; then
    mkdir -p "${DEST_DIR}/etc/udev/rules.d"
    cp -v udev/* "${DEST_DIR}/etc/udev/rules.d/"
    chmod 644 "${DEST_DIR}/etc/udev/rules.d/"*.rules
fi

# 8. Logind Physical Button Handling
if [ -d "logind" ]; then
    mkdir -p "${DEST_DIR}/etc/systemd/logind.conf.d"
    cp -v logind/* "${DEST_DIR}/etc/systemd/logind.conf.d/"
    chmod 644 "${DEST_DIR}/etc/systemd/logind.conf.d/"*.conf
fi

# 9. Create runtime state directories
mkdir -p "${DEST_DIR}/var/lib/sweet" "${DEST_DIR}/etc/default"
chmod 755 "${DEST_DIR}/var/lib/sweet"

echo "[+] Master installation complete! All subsystems and suites are deployed to ${DEST_DIR}."
