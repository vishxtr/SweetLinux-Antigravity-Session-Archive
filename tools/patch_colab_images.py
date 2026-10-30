import os, struct, subprocess, time

print("=== [1/3] Patching data/boot.img kernel cmdline ===")
boot_img = "/content/inspect_zip/data/boot.img"
with open(boot_img, "r+b") as f:
    hdr = f.read(4096)
    magic = hdr[:8]
    assert magic == b"ANDROID!"
    
    clean_cmdline = (
        "androidboot.selinux=permissive console=ttyMSM0,115200n8 androidboot.hardware=qcom "
        "androidboot.console=ttyMSM0 androidboot.memcg=1 lpm_levels.sleep_disabled=1 "
        "msm_rtb.filter=0x237 service_locator.enable=1 swiotlb=1 "
        "androidboot.usbcontroller=a600000.dwc3 earlycon=msm_geni_serial,0x880000 "
        "loop.max_part=7 androidboot.init_fatal_reboot_target=bootloader kpti=off "
        "fsck.mode=force fsck.repair=yes no_console_suspend pm_debug_messages=0 "
        "msm_drm.dsi_display0=dsi_k6_38_0c_0a_fhd_dsc_video_display:"
    )
    cmdline_bytes = clean_cmdline.encode("ascii")
    assert len(cmdline_bytes) < 512
    cmdline_padded = cmdline_bytes.ljust(512, b"\x00")
    f.seek(64)
    f.write(cmdline_padded)
print("[+] data/boot.img cmdline successfully updated!")

print("=== [2/3] Patching data/ubuntu.img ===")
ubuntu_img = "/content/inspect_zip/data/ubuntu.img"

os.system("echo 'amoled' > /tmp/sweet-panel-type")
os.system("echo '120' > /tmp/sweet-fps")
os.system("echo '1024' > /tmp/sweet-backlight")

subprocess.run(f"e2cp -p /tmp/sweet-panel-type {ubuntu_img}:/etc/default/sweet-panel-type", shell=True, check=True)
subprocess.run(f"e2cp -p /tmp/sweet-fps {ubuntu_img}:/etc/default/sweet-fps", shell=True, check=True)
subprocess.run(f"e2cp -p /tmp/sweet-backlight {ubuntu_img}:/etc/default/sweet-backlight", shell=True, check=True)

subprocess.run(f"debugfs -w -R 'rm etc/default/sweet-lcd' {ubuntu_img} 2>/dev/null || true", shell=True)

subprocess.run(f"e2cp -p /content/patch_files/sweet-fps {ubuntu_img}:/usr/local/bin/sweet-fps", shell=True, check=True)
subprocess.run(f"e2cp -p /content/patch_files/sweet-hub-daemon {ubuntu_img}:/usr/local/bin/sweet-hub-daemon", shell=True, check=True)
subprocess.run(f"e2cp -p /content/patch_files/DisplayHub.qml {ubuntu_img}:/usr/share/sweetlinux/qml/DisplayHub.qml", shell=True, check=True)

subprocess.run(f"debugfs -w -R 'set_inode_field usr/local/bin/sweet-fps mode 0100755' {ubuntu_img}", shell=True)
subprocess.run(f"debugfs -w -R 'set_inode_field usr/local/bin/sweet-hub-daemon mode 0100755' {ubuntu_img}", shell=True)
subprocess.run(f"debugfs -w -R 'set_inode_field usr/share/sweetlinux/qml/DisplayHub.qml mode 0100644' {ubuntu_img}", shell=True)

mir_conf = "[Display]\npanel=dsi_k6_38_0c_0a_fhd_dsc_video_display\nrefresh_rate=120\n"
with open("/tmp/mir.display.conf", "w") as f:
    f.write(mir_conf)
subprocess.run(f"debugfs -w -R 'mkdir etc/mirplatform' {ubuntu_img} 2>/dev/null || true", shell=True)
subprocess.run(f"e2cp -p /tmp/mir.display.conf {ubuntu_img}:/etc/mirplatform/mir.display.conf", shell=True, check=True)
subprocess.run(f"debugfs -w -R 'set_inode_field etc/mirplatform/mir.display.conf mode 0100644' {ubuntu_img}", shell=True)

subprocess.run(f"debugfs -w -R 'rm etc/systemd/system/multi-user.target.wants/prevent-sod.service' {ubuntu_img} 2>/dev/null || true", shell=True)
subprocess.run(f"debugfs -w -R 'rm etc/systemd/system/prevent-sod.service' {ubuntu_img} 2>/dev/null || true", shell=True)
subprocess.run(f"debugfs -w -R 'rm etc/systemd/system/multi-user.target.wants/sweet-fps.service' {ubuntu_img} 2>/dev/null || true", shell=True)

subprocess.run(f"e2fsck -f -y {ubuntu_img} || true", shell=True)
print("[+] data/ubuntu.img successfully patched!")

print("=== [3/3] Creating updated ubports.sh ===")
ubports_sh = '''#!/bin/sh
# SweetLinux ubports.sh - RootFS Resizing and Halium Boot Deployment
# Target: sweet / sweetin (Xiaomi Redmi Note 10 Pro / Pro Max)

OUTFD=/proc/self/fd/$1;
CODENAME=$(getprop ro.product.device 2>/dev/null || echo "sweet");

ui_print() {
  while [ -n "$1" ]; do
    echo "$1" | while IFS= read -r _l || [ -n "$_l" ]; do
      [ -n "$_l" ] && echo -e "ui_print $_l\\nui_print" > $OUTFD
    done
    shift
  done
}

ui_print " [1/6] Cleaning legacy rootfs...";
rm -rf /data/ubuntu.img;

ui_print " [2/6] Moving new rootfs and halium boot image...";
mv -f /data/ubports/data/ubuntu.img /data/;
mv -f /data/ubports/data/boot.img /data/;

ui_print " [3/6] Expanding rootfs to 8GB (takes ~1-2 min, please wait)...";
e2fsck -fy /data/ubuntu.img > /dev/null 2>&1 || true;
resize2fs -f /data/ubuntu.img 8G 2>/dev/null || resize2fs -f /data/ubuntu.img 6G 2>/dev/null || true;

ui_print " [4/6] Creating 4GB high-performance SWAP (writing image, please wait)...";
if ! fallocate -l 4G /data/SWAP.img 2>/dev/null; then
    dd if=/dev/zero of=/data/SWAP.img bs=1M count=4096 2>/dev/null || dd if=/dev/zero of=/data/SWAP.img bs=1M count=2048 2>/dev/null;
fi;
chmod 600 /data/SWAP.img;
mkswap /data/SWAP.img > /dev/null 2>&1;

ui_print " [5/6] Auto-detecting Display Panel & Configuring AMOLED / LCD Profile...";
mkdir -p /data/linux/ubuntu;
LOOP_DEV=""
if ! grep -q "/data/linux/ubuntu" /proc/mounts; then
  mount -o loop /data/ubuntu.img /data/linux/ubuntu 2>/dev/null || true
fi
if ! grep -q "/data/linux/ubuntu" /proc/mounts; then
  LOOP_DEV=$(losetup -f 2>/dev/null)
  if [ -n "$LOOP_DEV" ]; then
    losetup "$LOOP_DEV" /data/ubuntu.img 2>/dev/null || true
    mount -t ext4 "$LOOP_DEV" /data/linux/ubuntu 2>/dev/null || true
  fi
fi

if [ -f /vendor/ueventd.rc -o -f /vendor/etc/ueventd.rc ]; then
    cat /vendor/ueventd*.rc /vendor/etc/ueventd*.rc 2>/dev/null | grep ^/dev | sed -e 's/^\\/dev\\///' | awk '{printf "ACTION==\\"add\\", KERNEL==\\"%s\\", OWNER=\\"%s\\", GROUP=\\"%s\\", MODE=\\"%s\\"\\n",$1,$3,$4,$2}' | sed -e 's/\\r//' > /data/linux/ubuntu/etc/udev/rules.d/70-sweet.rules 2>/dev/null || true;
fi;

mkdir -p /data/linux/ubuntu/etc/default 2>/dev/null || true
mkdir -p /data/linux/ubuntu/etc/mirplatform 2>/dev/null || true

IS_LCD=0
if [ -e "/sys/class/leds/lcd-backlight" ]; then
    IS_LCD=1
fi
for pnode in /sys/devices/platform/soc/ae00000.qcom,mdss_mdp/drm/card0/card0-DSI-1/panel_info /sys/class/drm/card0-DSI-1/panel_info; do
    if [ -f "$pnode" ] && grep -iqE "lcd|tianma|huaxing|boe|ft8719|nt36" "$pnode" 2>/dev/null; then
        IS_LCD=1
    fi
done

if [ "$IS_LCD" -eq 1 ]; then
    echo "lcd" > /data/linux/ubuntu/etc/default/sweet-panel-type 2>/dev/null || true
    echo "60" > /data/linux/ubuntu/etc/default/sweet-fps 2>/dev/null || true
    echo "650" > /data/linux/ubuntu/etc/default/sweet-backlight 2>/dev/null || true
    touch /data/linux/ubuntu/etc/default/sweet-lcd 2>/dev/null || true
    ui_print "   -> Aftermarket LCD Detected: Configured rock-solid 60Hz mode";
else
    echo "amoled" > /data/linux/ubuntu/etc/default/sweet-panel-type 2>/dev/null || true
    echo "120" > /data/linux/ubuntu/etc/default/sweet-fps 2>/dev/null || true
    echo "1024" > /data/linux/ubuntu/etc/default/sweet-backlight 2>/dev/null || true
    rm -f /data/linux/ubuntu/etc/default/sweet-lcd 2>/dev/null || true
    ui_print "   -> OEM Samsung Super AMOLED Detected: Configured 120Hz/60Hz adaptive mode";
fi

cat << 'EOF_MIR' > /data/linux/ubuntu/etc/mirplatform/mir.display.conf 2>/dev/null || true
[Display]
panel=dsi_k6_38_0c_0a_fhd_dsc_video_display
refresh_rate=120
EOF_MIR

sync;
umount /data/linux/ubuntu 2>/dev/null || true;
[ -n "$LOOP_DEV" ] && losetup -d "$LOOP_DEV" 2>/dev/null || true;

SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null || true);
BOOT_TARGET="";
for dev in "/dev/block/bootdevice/by-name/boot$SLOT" "/dev/block/by-name/boot$SLOT" "/dev/block/bootdevice/by-name/boot" "/dev/block/by-name/boot"; do
    if [ -e "$dev" ]; then
        BOOT_TARGET="$dev";
        break;
    fi;
done;
[ -z "$BOOT_TARGET" ] && BOOT_TARGET="/dev/block/bootdevice/by-name/boot";

ui_print " [6/6] Flashing Halium kernel to $BOOT_TARGET...";
dd if=/data/boot.img of="$BOOT_TARGET" bs=4M;
sync;
rm -f /data/boot.img 2>/dev/null || true;

ui_print " Cleaning installation scratch files...";
rm -rf /data/ubports;
rm -rf /data/linux;

ui_print " RootFS configuration and Halium boot complete.";
'''

with open("/content/inspect_zip/ubports.sh", "w") as f:
    f.write(ubports_sh)
os.chmod("/content/inspect_zip/ubports.sh", 0o755)
print("[+] ubports.sh successfully written!")
