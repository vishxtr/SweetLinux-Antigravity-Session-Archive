#!/usr/bin/env python3
"""
SweetLinux Build Orchestration Pipeline
Coordinates cloud compilation, rootfs generation, and artifact publishing.
"""

import os
import sys
import time
import subprocess
import json

def run_remote(code, session="sweet_session", timeout=600):
    cmd = f"colab exec -s {session}"
    p = subprocess.Popen(cmd, shell=True, stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    out, err = p.communicate(input=code, timeout=timeout)
    return p.returncode, out, err

def stage_1_preflight():
    print("\n--- STAGE 1: Environment Preflight Check ---")
    ret = subprocess.run(["python3", "/data/data/com.termux/files/home/sweetlinux/scripts/environment_check.py"])
    if ret.returncode != 0:
        raise RuntimeError("Preflight verification failed!")
    print("[+] Preflight check PASSED.")

def stage_2_prepare_cloud():
    print("\n--- STAGE 2: Preparing Cloud Build Environment on Colab ---")
    code = """
import os, subprocess
print('[Cloud] Setting up workspace in /content/sweetlinux_build...')
os.makedirs('/content/sweetlinux_build/out', exist_ok=True)
res = subprocess.run('sudo apt-get update -qq && sudo apt-get install -y -qq debootstrap qemu-user-static e2fsprogs zip unzip', shell=True)
print('[Cloud] Dependencies installed with exit code:', res.returncode)
"""
    code_ret, out, err = run_remote(code)
    print(out)
    if code_ret != 0:
        raise RuntimeError(f"Cloud setup failed: {err}")
    print("[+] Cloud workspace READY.")

def stage_3_build_rootfs():
    print("\n--- STAGE 3: Building Minimal Ubuntu 24.04 ARM64 Rootfs ---")
    code = """
import os, subprocess, hashlib
rootfs = '/content/sweetlinux_build/rootfs'
base_tar = '/content/sweetlinux_build/out/ubuntu-base-24.04.5-base-arm64.tar.gz'
out_tar = '/content/sweetlinux_build/out/sweetlinux-rootfs-arm64.tar.gz'

if not os.path.exists(base_tar):
    url = 'http://cdimage.ubuntu.com/ubuntu-base/releases/24.04/release/ubuntu-base-24.04.5-base-arm64.tar.gz'
    print('[Cloud] Fetching official Canonical Ubuntu 24.04.5 ARM64 base...')
    subprocess.run(f'curl -L -o {base_tar} {url}', shell=True, check=True)

print('[Cloud] Extracting base rootfs...')
subprocess.run(f'sudo rm -rf {rootfs} && sudo mkdir -p {rootfs}', shell=True)
subprocess.run(f'sudo tar -xzf {base_tar} -C {rootfs}', shell=True, check=True)

print('[Cloud] Injecting DNS & network configuration...')
with open(f'{rootfs}/etc/resolv.conf', 'w') as f:
    f.write('nameserver 8.8.8.8\\nnameserver 1.1.1.1\\n')
with open(f'{rootfs}/etc/hostname', 'w') as f:
    f.write('sweetlinux\\n')
with open(f'{rootfs}/etc/hosts', 'w') as f:
    f.write('127.0.0.1 localhost sweetlinux\\n::1 localhost ip6-localhost ip6-loopback\\n')

print('[Cloud] Injecting SweetLinux supervisor...')
os.makedirs(f'{rootfs}/etc/sweetlinux', exist_ok=True)
with open(f'{rootfs}/etc/sweetlinux/version', 'w') as f:
    f.write('SweetLinux 1.0.0-rc1 (Ubuntu 24.04.5 LTS ARM64)\\nTarget: Redmi Note 10 Pro Max (sweet / sweetin)\\n')

service_sh = '''#!/bin/sh
# SweetLinux Environment Supervisor
echo '[SweetLinux] Initializing hybrid userspace...'
[ ! -d /proc/1 ] && mount -t proc proc /proc 2>/dev/null
[ ! -d /sys/kernel ] && mount -t sysfs sysfs /sys 2>/dev/null
[ ! -d /dev/pts ] && mount -t devpts devpts /dev/pts 2>/dev/null
if [ -x /usr/sbin/sshd ]; then
    mkdir -p /run/sshd
    /usr/sbin/sshd -p 2222
    echo '[SweetLinux] OpenSSH server active on port 2222.'
fi
echo '[SweetLinux] Ready.'
'''
with open(f'{rootfs}/etc/sweetlinux/sweetlinux-service.sh', 'w') as f:
    f.write(service_sh)
os.chmod(f'{rootfs}/etc/sweetlinux/sweetlinux-service.sh', 0o755)

print('[Cloud] Archiving clean rootfs...')
subprocess.run(f'cd {rootfs} && sudo tar -czf {out_tar} .', shell=True, check=True)
print('[Cloud] Rootfs payload created successfully!')
"""
    code_ret, out, err = run_remote(code, timeout=900)
    print(out)
    if code_ret != 0:
        raise RuntimeError(f"Rootfs build failed: {err}")
    print("[+] Rootfs payload built successfully.")

def stage_4_sync_drive():
    print("\n--- STAGE 4: Publishing Artifacts to Google Drive ---")
    code = """
import os, subprocess, hashlib

out_dir = '/content/sweetlinux_build/out'
drive_rel = '/content/drive/MyDrive/SweetLinux/releases'
drive_chk = '/content/drive/MyDrive/SweetLinux/checksums'

os.makedirs(drive_rel, exist_ok=True)
os.makedirs(drive_chk, exist_ok=True)

for fname in os.listdir(out_dir):
    if fname.endswith('.tar.gz') or fname.endswith('.zip') or fname.endswith('.img'):
        src = os.path.join(out_dir, fname)
        dst = os.path.join(drive_rel, fname)
        print(f'[Cloud] Copying {fname} to Google Drive...')
        subprocess.run(f'cp -v {src} {dst}', shell=True, check=True)
        
        # Calculate SHA256
        sha = hashlib.sha256(open(dst, 'rb').read()).hexdigest()
        print(f'[Cloud] {fname} SHA256: {sha}')
        with open(os.path.join(drive_chk, 'SHA256SUMS.txt'), 'a') as f:
            f.write(f'{sha}  {fname}\\n')

print('[Cloud] All artifacts successfully published!')
"""
    code_ret, out, err = run_remote(code)
    print(out)
    if code_ret != 0:
        raise RuntimeError(f"Drive publish failed: {err}")
    print("[+] Drive synchronization complete.")

def main():
    print("==========================================================")
    print("      SWEETLINUX AUTOMATED BUILD ORCHESTRATION           ")
    print("==========================================================")
    start_time = time.time()
    
    stage_1_preflight()
    stage_2_prepare_cloud()
    stage_3_build_rootfs()
    stage_4_sync_drive()
    
    elapsed = round(time.time() - start_time, 2)
    print(f"\n[+] SweetLinux Build Pipeline Completed in {elapsed}s!")

if __name__ == "__main__":
    main()
