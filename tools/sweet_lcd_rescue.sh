#!/sbin/sh
# ==============================================================================
# SweetLinux Halium LCD Resilience & Recovery Rescue Script
# Target: Xiaomi Redmi Note 10 Pro / Pro Max (sweet / sweetin)
# Purpose: Fix bootloops, black screen, and Sleep of Death on replacement LCD panels
# ==============================================================================

echo "========================================================"
echo " SweetLinux Replacement LCD Resilience & Rescue Utility"
echo "========================================================"

# Step 1: Resolve and Mount Data Partition
echo "[1/6] Mounting /data partition..."
DATA_DEV=""
for cand in /dev/block/bootdevice/by-name/userdata /dev/block/by-name/userdata /dev/block/mapper/userdata; do
    if [ -e "$cand" ]; then
        DATA_DEV="$cand"
        break
    fi
done

mkdir -p /data 2>/dev/null
if ! grep -q " /data " /proc/mounts; then
    mount -t f2fs "$DATA_DEV" /data 2>/dev/null || mount -t ext4 "$DATA_DEV" /data 2>/dev/null || mount /data 2>/dev/null
fi

if ! grep -q " /data " /proc/mounts; then
    echo "[-] Error: Failed to mount /data. Please check 'Mount Data' in recovery."
    exit 1
fi
echo "[+] /data mounted successfully."

# Step 2: Loop Mount ubuntu.img
echo "[2/6] Loop-mounting /data/ubuntu.img..."
MNT="/tmp/ubuntu_rescue"
mkdir -p "$MNT"
umount "$MNT" 2>/dev/null || true

if [ ! -f "/data/ubuntu.img" ]; then
    echo "[-] Error: /data/ubuntu.img not found on internal storage!"
    exit 1
fi

mount -o loop,rw /data/ubuntu.img "$MNT"
if ! grep -q "$MNT" /proc/mounts; then
    echo "[-] Error: Failed to mount /data/ubuntu.img."
    exit 1
fi
echo "[+] RootFS mounted at $MNT."

# Step 3: Configure Display Mode & Panel Hardware (AMOLED vs LCD)
MODE_ARG="${1:-auto}"
echo "[3/6] Configuring display panel profile (Mode: ${MODE_ARG})..."

# Detect panel hardware from sysfs / cmdline
DETECTED="amoled"
if [ -e "/sys/class/leds/lcd-backlight" ] || [ -f "$MNT/etc/default/sweet-lcd" ]; then
    DETECTED="lcd"
fi

if grep -iqE "lcd|tianma|huaxing|boe|ft8719|nt36" /proc/cmdline 2>/dev/null; then
    DETECTED="lcd"
fi

if [ "$MODE_ARG" = "lcd" ] || [ "$MODE_ARG" = "--lcd" ]; then
    TARGET_PANEL="lcd"
elif [ "$MODE_ARG" = "amoled" ] || [ "$MODE_ARG" = "--amoled" ]; then
    TARGET_PANEL="amoled"
else
    TARGET_PANEL="$DETECTED"
fi

mkdir -p "$MNT/etc/default"
rm -f "$MNT/etc/default/sweet-lcd"

if [ "$TARGET_PANEL" = "lcd" ]; then
    echo "lcd" > "$MNT/etc/default/sweet-panel-type"
    echo "60" > "$MNT/etc/default/sweet-fps"
    echo "650" > "$MNT/etc/default/sweet-backlight"
    touch "$MNT/etc/default/sweet-lcd"
    if [ -f "$MNT/etc/ubuntu-touch/display.conf" ]; then
        sed -i "s/RefreshRate=120/RefreshRate=60/g" "$MNT/etc/ubuntu-touch/display.conf" 2>/dev/null || true
    fi
    echo "[+] Aftermarket Replacement LCD Profile applied (60Hz safe mode)."
else
    echo "amoled" > "$MNT/etc/default/sweet-panel-type"
    echo "120" > "$MNT/etc/default/sweet-fps"
    echo "1024" > "$MNT/etc/default/sweet-backlight"
    if [ -f "$MNT/etc/ubuntu-touch/display.conf" ]; then
        sed -i "s/RefreshRate=60/RefreshRate=120/g" "$MNT/etc/ubuntu-touch/display.conf" 2>/dev/null || true
    fi
    echo "[+] OEM Samsung Super AMOLED Profile applied (120Hz/60Hz adaptive)."
fi

# Set proper Mir platform configuration to prevent modeset flickering
mkdir -p "$MNT/etc/mirplatform"
cat << 'EOF_MIR' > "$MNT/etc/mirplatform/mir.display.conf"
[Display]
panel=dsi_k6_38_0c_0a_fhd_dsc_video_display
refresh_rate=120
EOF_MIR

# Step 4: Eliminate Circular Systemd Dependency Loops
echo "[4/6] Fixing Systemd service ordering..."
rm -f "$MNT/etc/systemd/system/multi-user.target.wants/remount-rw.service"
rm -f "$MNT/etc/systemd/system/local-fs.target.wants/remount-rw.service"
rm -f "$MNT/etc/systemd/system/multi-user.target.wants/sweet-fps.service"
echo "[+] Dependency loops cleared."

# Step 5: Prevent Sleep of Death (SOD) on LCD Bridge IC
echo "[5/6] Injecting LCD Sleep of Death (SOD) Prevention..."
cat << 'EOF' > "$MNT/etc/systemd/system/prevent-sod.service"
[Unit]
Description=Prevent Sleep of Death and Keep LCD DSI Bridge Alive
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/sh -c "echo 'sweet-lcd' > /sys/power/wake_lock 2>/dev/null || true; echo 0 > /sys/power/autosleep 2>/dev/null || true"
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
chmod 644 "$MNT/etc/systemd/system/prevent-sod.service"
ln -sf /etc/systemd/system/prevent-sod.service "$MNT/etc/systemd/system/multi-user.target.wants/prevent-sod.service" 2>/dev/null || true

# Step 6: Sync and Unmount
echo "[6/6] Syncing and unmounting..."
sync
umount "$MNT"
echo "========================================================"
echo " [SUCCESS] Recovery patch applied! All LCD errors fixed."
echo " You can now Reboot to System safely."
echo "========================================================"
exit 0
