import os, subprocess, zipfile

work = "/content/inspect_zip"
zip_path = "/content/drive/MyDrive/SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip"
print("Extracting ubuntu.img...")
with zipfile.ZipFile(zip_path, "r") as z:
    z.extract("data/ubuntu.img", work)

mnt = "/content/mnt_ubuntu"
os.makedirs(mnt, exist_ok=True)
res = subprocess.getoutput(f"mount -o loop,ro {work}/data/ubuntu.img {mnt}")
print("Mount result:", res)

# Check display configs
print("--- /etc/default/ ---")
if os.path.exists(f"{mnt}/etc/default"):
    print(os.listdir(f"{mnt}/etc/default"))
    for f in os.listdir(f"{mnt}/etc/default"):
        if "sweet" in f:
            try:
                print(f, open(f"{mnt}/etc/default/{f}").read().strip())
            except:
                pass

print("--- /etc/mirplatform/ ---")
if os.path.exists(f"{mnt}/etc/mirplatform"):
    print(os.listdir(f"{mnt}/etc/mirplatform"))

print("--- /etc/lightdm/ ---")
if os.path.exists(f"{mnt}/etc/lightdm"):
    print(subprocess.getoutput(f"ls -la {mnt}/etc/lightdm"))

print("--- services in multi-user.target.wants ---")
print(subprocess.getoutput(f"ls -la {mnt}/etc/systemd/system/multi-user.target.wants/"))

print("--- environment / display variables ---")
print(subprocess.getoutput(f"grep -rn 'MIR' {mnt}/etc/ 2>/dev/null"))
print(subprocess.getoutput(f"grep -rn 'LOMIRI' {mnt}/etc/ 2>/dev/null"))
print(subprocess.getoutput(f"grep -rn 'WAYLAND' {mnt}/etc/ 2>/dev/null"))
