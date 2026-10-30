import os, subprocess, shutil, hashlib, time

t0 = time.time()
print("=== [1/4] Copying master installer to fast local NVMe ===")
drive_zip = "/content/drive/MyDrive/SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip"
work_zip = "/content/working_full_installer.zip"
if not os.path.exists(work_zip):
    shutil.copyfile(drive_zip, work_zip)
print(f"[+] Staged to {work_zip} ({os.path.getsize(work_zip)} bytes)")

print("=== [2/4] Updating archive with AMOLED patched boot.img, ubuntu.img, ubports.sh ===")
cmd = "cd /content/inspect_zip && 7z u /content/working_full_installer.zip ubports.sh data/boot.img data/ubuntu.img"
res = subprocess.run(cmd, shell=True, capture_output=True, text=True)
print(res.stdout[-600:])
if res.returncode != 0:
    print("Error:", res.stderr)
    raise RuntimeError("7z update failed")

print("=== [3/4] Verifying archive integrity ===")
res_t = subprocess.run("7z t /content/working_full_installer.zip", shell=True, capture_output=True, text=True)
print(res_t.stdout[-300:])
if res_t.returncode != 0:
    print("Error:", res_t.stderr)
    raise RuntimeError("Zip integrity test failed")

print("=== [4/4] Publishing verified fixed installer to Google Drive ===")
dests = [
    "/content/drive/MyDrive/SweetLinux/installer/SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip",
    "/content/drive/MyDrive/SweetLinux-Halium-CyberNeon-v1.4-LCD-Resilient-Full-Installer.zip"
]

# Calculate sha256
h = hashlib.sha256()
with open(work_zip, "rb") as f:
    while chunk := f.read(1024 * 1024):
        h.update(chunk)
sha = h.hexdigest()
size_bytes = os.path.getsize(work_zip)

print(f"File size: {size_bytes} bytes ({size_bytes/(1024*1024):.2f} MB)")
print(f"SHA-256:   {sha}")

for dst in dests:
    print(f"Publishing to {dst}...")
    shutil.copyfile(work_zip, dst)
    print(" -> Done")

print(f"\n=================================================================")
print(f" [SUCCESS] AMOLED Certified Installer Published in {time.time()-t0:.1f}s!")
print(f"=================================================================")
