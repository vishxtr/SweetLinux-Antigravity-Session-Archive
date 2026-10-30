# SweetLinux Engineering Toolset & Daemons

This directory contains the production-grade automation scripts, diagnostic utilities, and custom daemon services developed and refined during the SweetLinux development and debugging sessions.

---

## Tool Index

### 1. Build, Packaging & Audit Engine
- **[`audit_installer.py`](audit_installer.py)**:
  - Deep-verifies TWRP flashable ZIPs.
  - Enforces the **Entry #0 Rule** (`META-INF/com/google/android/update-binary` must begin at offset 0).
  - Validates ext4 sparse and raw filesystem superblocks for `system.img` and `halium_boot.img`.
  - Checks for the presence of the AMOLED resiliency scripts and absence of deprecated flags.
- **[`patch_colab_images.py`](patch_colab_images.py)**:
  - Automates kernel cmdline extraction and repacking (`abootimg` / `mkbootimg`).
  - Purges `video=vfb:enable` and `console=tty0` from boot parameters.
  - Injects `msm_drm.dsi_display0=1` to guarantee hardware modesetting.
  - Mounts rootfs and vendor loopbacks to apply hardware fixes and dynamic panel detection.
- **[`repack_and_publish.py`](repack_and_publish.py)**:
  - Repacks ZIP installers with deterministic entry ordering.
  - Calculates SHA-256 digests.
  - Syncs directly to Google Drive with automated flush and uploads release assets to GitHub.
- **[`environment_check.py`](environment_check.py)**:
  - Verifies host dependencies (`e2fsprogs`, `abootimg`, `zip`, `python3`, `adb`, `fastboot`).
- **[`inspect_script.py`](inspect_script.py)**:
  - High-speed updater-script syntax checker and assert validator.

### 2. Device Daemons & Hardware Support
- **[`sweet-fps`](sweet-fps)**:
  - Adaptive display refresh rate manager (60Hz / 120Hz).
  - Eliminates CRTC vsync interrupt storms by utilizing a 1000ms measurement sampling window.
  - Automatically identifies whether the device is fitted with the OEM Samsung EA8076 Super AMOLED or an aftermarket IPS LCD panel.
- **[`sweet-hub-daemon`](sweet-hub-daemon)**:
  - Background Python daemon listening to sysfs and D-Bus events for brightness, battery, thermal management, and dynamic hardware toggles.
- **[`sweet_lcd_rescue.sh`](sweet_lcd_rescue.sh)**:
  - Emergency shell rescue utility runnable directly from TWRP terminal or ADB shell to reconfigure display parameters without re-flashing.
- **[`DisplayHub.qml`](DisplayHub.qml)**:
  - Native Lomiri (Ubuntu Touch) UI component for the system settings app, providing seamless sliders for refresh rate, panel boost, and AMOLED burn-in protection.
- **[`sweet-gestures-daemon`](sweet-gestures-daemon)**:
  - Translates touch gestures (double tap to wake, swipe down) via evdev events into Lomiri power and display state changes.
- **[`sweet-audio-init`](sweet-audio-init)**:
  - Initializes ALSA UCM and PulseAudio routing for dual stereo speakers and dual microphones.
- **[`sweet-battery-hub`](sweet-battery-hub)**:
  - Monitors charging current and thermals via Qualcomm PM6150 / SMB1395 IC sysfs nodes.
- **[`sweet-fingerprint-manager`](sweet-fingerprint-manager)**:
  - Bridge daemon between Goodix / FPC fingerprint sensors and PAM.
- **[`sweet-ir-remote`](sweet-ir-remote)**:
  - Userspace CLI to send consumer IR pulses through the top IR blaster (`/dev/spidev0.0` / `/sys/class/rc`).
- **[`sweet-play-integrity`](sweet-play-integrity)**:
  - Prop injection utility for Halium container to pass safety and integrity checks.
- **[`sweet-usb-manager`](sweet-usb-manager)**:
  - Configures USB gadget modes (`rndis,adb` for network tethering + debugging, `mtp` for file transfer).
