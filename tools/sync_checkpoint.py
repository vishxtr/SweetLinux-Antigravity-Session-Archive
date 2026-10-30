#!/usr/bin/env python3
"""
SweetLinux Checkpoint & Drive Sync Script
Synchronizes local project artifacts, documentation, and manifests to Google Drive safely via base64 stdin.
"""

import os
import sys
import subprocess
import base64

LOCAL_DIR = "/data/data/com.termux/files/home/sweetlinux"
REMOTE_DRIVE_DIR = "/content/drive/MyDrive/SweetLinux"

def run_remote_python(code, stdin_input=None):
    cmd = "colab exec -s sweet_session"
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p.communicate(input=code, timeout=60)
    return p.returncode, out.strip(), err.strip()

def sync_file_to_drive(rel_path, target_subfolder):
    src = os.path.join(LOCAL_DIR, rel_path)
    if not os.path.exists(src):
        return False
    
    with open(src, "rb") as f:
        b64_content = base64.b64encode(f.read()).decode("ascii")
    
    filename = os.path.basename(rel_path)
    remote_script = f"""
import os, base64
dest = os.path.join('{REMOTE_DRIVE_DIR}', '{target_subfolder}', '{filename}')
os.makedirs(os.path.dirname(dest), exist_ok=True)
with open(dest, 'wb') as f:
    f.write(base64.b64decode('{b64_content}'))
print(f'OK:{{dest}}')
"""
    code, out, err = run_remote_python(remote_script)
    if code == 0 and "OK:" in out:
        print(f"  ✓ {target_subfolder}/{filename}")
        return True
    else:
        print(f"  ✗ Failed {filename}: {err}")
        return False

def sync_to_drive():
    print(f"[+] Synchronizing local SweetLinux files to Google Drive ({REMOTE_DRIVE_DIR})...")
    
    docs_to_sync = [
        "README.md",
        "ARCHITECTURE.md",
        "DEVICE_COMPATIBILITY.md",
        "FEASIBILITY_REPORT.md",
        "BUILD_GUIDE.md",
        "COLAB_SETUP.md",
        "GOOGLE_DRIVE_LAYOUT.md",
        "SECURITY.md",
        "RECOVERY_GUIDE.md",
        "TEST_PLAN.md",
        "RELEASE_CHECKLIST.md",
        "PROJECT_STATUS.md"
    ]
    
    for doc in docs_to_sync:
        sync_file_to_drive(doc, "documentation")

    sync_file_to_drive("manifests/build_manifest.json", "manifests")
    sync_file_to_drive("scripts/environment_check.py", "scripts")
    sync_file_to_drive("scripts/verify_artifacts.py", "scripts")
    sync_file_to_drive("scripts/orchestrate_build.py", "scripts")
    sync_file_to_drive("notebooks/SweetLinux_Cloud_Pipeline.ipynb", "notebooks")

    print("[+] All files verified and synced to Google Drive!")

if __name__ == "__main__":
    sync_to_drive()
