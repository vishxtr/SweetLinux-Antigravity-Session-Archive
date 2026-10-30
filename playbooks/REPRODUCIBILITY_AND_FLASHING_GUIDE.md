# SweetLinux Flashing & Reproduction Playbook

This step-by-step guide provides instructions for installing and reproducing **SweetLinux** (Halium 10 / Ubuntu Touch CyberNeon v1.4) on the Xiaomi Redmi Note 10 Pro / Pro Max (`sweet` / `sweetin`).

---

## 1. Prerequisites

- **Device:** Xiaomi Redmi Note 10 Pro or Redmi Note 10 Pro Max (`sweet` / `sweetin`).
- **Bootloader:** Unlocked.
- **Base Firmware:** Official MIUI 12.5.8+ or MIUI 13.0.x (Android 11/12 Vendor firmware installed).
- **Recovery:** TWRP 3.6+ or OrangeFox Recovery R11.1+.
- **Official Certified Installer:**
  - File: `SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip`
  - Size: `2,063,054,832 bytes`
  - SHA-256: `40d69899a7106b70865a7404cd2b8560e504e536d74cc051ed68ce7cd062172b`
  - Download: [GitHub Release v1.4.1-amoled-certified](https://github.com/vishxtr/SweetLinux/releases/tag/v1.4.1-amoled-certified)

---

## 2. Installation Steps (via TWRP)

1. **Reboot to Recovery:**
   Power off the phone, then hold `Volume Up + Power` until the TWRP splash screen appears.

2. **Wipe Partitions:**
   - Go to **Wipe** -> **Advanced Wipe**.
   - Select:
     - `Dalvik / ART Cache`
     - `Cache`
     - `System`
     - `Data` (Note: Formatting data may be required if previously encrypted).
   - Swipe to Wipe.

3. **Transfer or Locate Installer:**
   - If using a MicroSD card: Copy the zip to `/external_sd/` or `/storage/4AB1-CEA0/UBUNTU_TOUCH_SWEET/`.
   - If using ADB Sideload from PC / Termux:
     ```bash
     adb sideload SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip
     ```
   - Or install directly via TWRP GUI: Go to **Install**, select the zip file, and swipe to confirm.

4. **Installation Execution:**
   - The installer automatically mounts partitions, verifies the Entry #0 script, flashes `halium_boot.img`, writes the Ubuntu Touch ext4 rootfs into `userdata`, and executes the adaptive panel detection script.

5. **Reboot:**
   - Tap **Reboot System**.
   - First boot takes approximately 45-60 seconds while Lomiri generates its font cache and initializes D-Bus services.

---

## 3. Post-Boot Verification & Diagnostics

### Connecting via USB Networking:
SweetLinux exposes a USB RNDIS interface upon boot:
```bash
# On your host PC or Termux:
ssh phablet@10.15.19.82
# Default password: root or 0000 (if prompted)
```

### Checking Display Hardware State:
```bash
# Check detected panel type (amoled or lcd)
cat /etc/default/sweet-panel-type

# Verify active refresh rate
sweet-fps

# Toggle between 60Hz and 120Hz
sweet-fps --set 120
sweet-fps --set 60

# Test brightness scaling
echo 1024 | sudo tee /sys/class/backlight/panel0-backlight/brightness
```

### Emergency Rescue Tool (If Display Fails):
If testing modified kernels or encountering display issues, boot into TWRP recovery and execute:
```bash
adb shell /sdcard/sweet_lcd_rescue.sh
```
This forces recovery of panel brightness sysfs nodes and resets display settings.
