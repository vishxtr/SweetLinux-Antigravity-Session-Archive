#!/usr/bin/env python3
"""
SweetLinux Environment Preflight Verification Script
Audits:
1. Local Host / Termux / Android root access.
2. Target hardware identification (Redmi Note 10 Pro Max sweet/sweetin).
3. Google Colab CLI connectivity and session status.
4. Google Drive persistence and read/write integrity.
"""

import os
import sys
import json
import time
import hashlib
import subprocess
import shutil

def run_cmd(cmd, shell=True, timeout=30):
    try:
        res = subprocess.run(cmd, shell=shell, capture_output=True, text=True, timeout=timeout)
        return res.returncode, res.stdout.strip(), res.stderr.strip()
    except Exception as e:
        return -1, "", str(e)

def audit_local():
    print("[1/4] Auditing Local Host Environment...")
    code, uname, _ = run_cmd("uname -a")
    code, uid_out, _ = run_cmd("id")
    code, root_out, _ = run_cmd("su -c 'id' 2>/dev/null")
    has_root = (code == 0 and "uid=0(root)" in root_out)
    
    device_info = {}
    if has_root:
        _, dev, _ = run_cmd("su -c 'getprop ro.product.device'")
        _, model, _ = run_cmd("su -c 'getprop ro.product.model'")
        _, release, _ = run_cmd("su -c 'getprop ro.build.version.release'")
        _, fp, _ = run_cmd("su -c 'getprop ro.build.fingerprint'")
        _, bat, _ = run_cmd("su -c 'cat /sys/class/power_supply/battery/capacity 2>/dev/null'")
        device_info = {
            "device": dev,
            "model": model,
            "android_version": release,
            "fingerprint": fp,
            "battery_pct": bat
        }
    
    df_data = shutil.disk_usage("/data")
    return {
        "kernel": uname,
        "user": uid_out,
        "has_root": has_root,
        "free_disk_gb": round(df_data.free / (1024**3), 2),
        "device": device_info
    }

def audit_colab():
    print("[2/4] Auditing Google Colab Remote VM...")
    code, sess_out, _ = run_cmd("colab sessions")
    if code != 0:
        return {"status": "FAILED", "error": "colab CLI returned non-zero"}
    
    is_active = "sweet_session" in sess_out
    vm_specs = {}
    if is_active:
        py_probe = """
import psutil, shutil, subprocess, json
vm = psutil.virtual_memory()
df = shutil.disk_usage('/content')
specs = {
    'cpus': psutil.cpu_count(logical=True),
    'ram_total_gb': round(vm.total / (1024**3), 2),
    'ram_avail_gb': round(vm.available / (1024**3), 2),
    'disk_content_free_gb': round(df.free / (1024**3), 2),
    'os': subprocess.getoutput('lsb_release -d 2>/dev/null || cat /etc/issue').strip()
}
print('__SPEC_JSON__' + json.dumps(specs))
"""
        cmd = f"echo \"{py_probe}\" | colab exec -s sweet_session"
        code, out, err = run_cmd(cmd, timeout=30)
        if "__SPEC_JSON__" in out:
            spec_str = out.split("__SPEC_JSON__")[-1].strip().split("\n")[0]
            try:
                vm_specs = json.loads(spec_str)
            except Exception:
                pass
    
    return {
        "session_active": is_active,
        "session_list": sess_out,
        "specs": vm_specs
    }

def audit_drive():
    print("[3/4] Auditing Google Drive Cloud Persistence...")
    test_nonce = f"nonce_{int(time.time())}"
    py_probe = f"""
import os, json, hashlib
base = '/content/drive/MyDrive/SweetLinux'
test_file = os.path.join(base, 'tests', 'audit_probe.tmp')
success = False
sha = ''
try:
    with open(test_file, 'w') as f:
        f.write('{test_nonce}')
    with open(test_file, 'r') as f:
        content = f.read()
    sha = hashlib.sha256(content.encode()).hexdigest()
    success = (content == '{test_nonce}')
    os.remove(test_file)
except Exception as e:
    err = str(e)
print(f'__DRIVE_STATUS__{{success}}:{{sha}}')
"""
    cmd = f"echo \"{py_probe}\" | colab exec -s sweet_session"
    code, out, _ = run_cmd(cmd, timeout=30)
    writable = False
    sha = ""
    if "__DRIVE_STATUS__" in out:
        parts = out.split("__DRIVE_STATUS__")[-1].strip().split(":")
        writable = (parts[0] == "True")
        sha = parts[1] if len(parts) > 1 else ""
    
    return {
        "mount_point": "/content/drive",
        "project_dir": "/content/drive/MyDrive/SweetLinux",
        "verified_writable": writable,
        "probe_sha256": sha
    }

def main():
    print("=" * 60)
    print("   SWEETLINUX AUTOMATED PREFLIGHT VERIFICATION MATRIX")
    print("=" * 60)
    
    report = {
        "timestamp": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
        "local": audit_local(),
        "colab": audit_colab(),
        "drive": audit_drive()
    }
    
    print("\n[4/4] SUMMARY RESULTS:")
    print(f"* Target Device: {report['local']['device'].get('model', 'Unknown')} ({report['local']['device'].get('device', 'Unknown')})")
    print(f"* Android Root: {'ACTIVE (uid=0)' if report['local']['has_root'] else 'NOT ACTIVE'}")
    print(f"* Local Storage Free: {report['local']['free_disk_gb']} GB")
    print(f"* Colab Session: {'READY' if report['colab']['session_active'] else 'OFFLINE'}")
    if report['colab']['specs']:
        print(f"  - vCPUs: {report['colab']['specs'].get('cpus')}, RAM: {report['colab']['specs'].get('ram_total_gb')} GB, Free Disk: {report['colab']['specs'].get('disk_content_free_gb')} GB")
    print(f"* Google Drive Persistence: {'VERIFIED WRITABLE' if report['drive']['verified_writable'] else 'FAILED'}")
    
    out_file = "/data/data/com.termux/files/home/sweetlinux/tests/preflight_results.json"
    os.makedirs(os.path.dirname(out_file), exist_ok=True)
    with open(out_file, "w") as f:
        json.dump(report, f, indent=2)
    print(f"\n[+] Full report saved to: {out_file}")
    
    all_ok = report['local']['has_root'] and report['colab']['session_active'] and report['drive']['verified_writable']
    print(f"[+] Overall Verdict: {'PASS - Ready for Build Orchestration' if all_ok else 'WARN - Review details'}")
    return 0 if all_ok else 1

if __name__ == "__main__":
    sys.exit(main())
