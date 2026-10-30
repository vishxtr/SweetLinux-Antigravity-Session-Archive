---
name: termux-voice
description: Use when enabling, fixing, or diagnosing microphone audio recording and speech-to-text (/voice) in Antigravity CLI (agy) on Android/Termux. Triggers on "voice", "microphone", "/voice", "speech to text", "audio record", "cannot find card 0", "transcription failed".
---

# Termux Voice Recognition & Microphone Setup Guide

This skill enables and repairs the `/voice` command (voice dictation & speech-to-text) in Antigravity CLI (`agy`) when running in **Termux on Android**.

---

## 1. Problem Architecture & Root Cause

When running `/voice` in `agy` on Linux, the audio subsystem in `audio.go` attempts to detect an available CLI recorder:
1. `pw-record` (PipeWire)
2. `arecord` (ALSA `alsa-utils`)

`agy` runs the recorder with:
```bash
arecord -q -f S16_LE -r 16000 -c 1 -t raw -
```
and streams raw 16kHz mono S16_LE PCM audio directly from `stdout` to Google's speech recognition RPC backend.

### Failure Breakdown in Termux:
1. **ALSA Has No Soundcards in Userspace**:
   Stock `arecord` talks directly to Linux ALSA kernel drivers (`/dev/snd/*`). On Android, non-root apps have no access to raw ALSA nodes, causing `arecord` to crash immediately:
   ```
   ALSA lib ... cannot find card '0'
   arecord: audio open error: No such file or directory
   audio.go: stopping the recorder failed: /data/data/com.termux/files/usr/bin/arecord exited unexpectedly: exit status 1
   ```
2. **Backend Rejection**:
   Because the recorder process crashes immediately without streaming any audio data, `agy` sends a 0-byte stream to the backend, causing:
   ```
   No audio is being picked up. Check that your terminal app has microphone access...
   Transcription failed: backend stream error: rpc error: code = FailedPrecondition desc = Precondition check failed.
   ```
3. **PulseAudio Missing Input Source**:
   Termux includes native Android OpenSL ES audio recording through `module-sles-source.so`, but `/data/data/com.termux/files/usr/etc/pulse/default.pa` only loads playback (`module-sles-sink`) by default.

---

## 2. Automated Quick Fix

Run the automated configuration script included with this skill:

```bash
/data/data/com.termux/files/home/.agents/skills/termux-voice/scripts/setup-voice.sh
```

The script is idempotent and handles dependency checks, PulseAudio configuration, bridge script installation, and verification.

---

## 3. Manual Step-by-Step Procedure

If configuring manually or repairing on a clean install, follow these steps:

### Step 1: Install Dependencies
Ensure `pulseaudio` is installed in Termux:
```bash
pkg install -y pulseaudio
```

### Step 2: Configure PulseAudio OpenSL ES Microphone Source
Open `/data/data/com.termux/files/usr/etc/pulse/default.pa` and locate `load-module module-sles-sink`.
Immediately below it, add:
```pa
load-module module-sles-source
set-default-source OpenSL_ES_source
```

Restart PulseAudio:
```bash
pulseaudio -k 2>/dev/null || true
pulseaudio --start --exit-idle-time=-1 2>/dev/null
```

Verify that the microphone source is active:
```bash
pactl list sources short
# Expected output contains:
# 2   OpenSL_ES_source   module-sles-source.c   s16le 2ch 44100Hz   IDLE
```

### Step 3: Install the `arecord` Compatibility Bridge
Backup the broken ALSA symlink:
```bash
if [ -L /data/data/com.termux/files/usr/bin/arecord ]; then
    cp -P /data/data/com.termux/files/usr/bin/arecord /data/data/com.termux/files/usr/bin/arecord.alsa
fi
```

Create `/data/data/com.termux/files/usr/bin/arecord` with the following content:
```bash
#!/data/data/com.termux/files/usr/bin/bash
# Termux PulseAudio compatibility wrapper for arecord
# Enables microphone recording in Termux for apps expecting ALSA arecord

RATE=16000
CHANNELS=1
FORMAT=s16le
RAW=true
OUT_FILE=""

while [ $# -gt 0 ]; do
    case "$1" in
        -r|--rate)
            RATE="$2"
            shift 2
            ;;
        -r*)
            RATE="${1#-r}"
            shift
            ;;
        -c|--channels)
            CHANNELS="$2"
            shift 2
            ;;
        -c*)
            CHANNELS="${1#-c}"
            shift
            ;;
        -f|--format)
            case "$2" in
                S16_LE|s16le|S16LE) FORMAT="s16le" ;;
                S16_BE|s16be|S16BE) FORMAT="s16be" ;;
                U8|u8) FORMAT="u8" ;;
                S32_LE|s32le|S32LE) FORMAT="s32le" ;;
                FLOAT_LE|float32le) FORMAT="float32le" ;;
                *) FORMAT="s16le" ;;
            esac
            shift 2
            ;;
        -t|--file-type)
            if [ "$2" = "raw" ]; then
                RAW=true
            else
                RAW=false
            fi
            shift 2
            ;;
        -q|--quiet|-v|--verbose|-N|--nonblock)
            shift
            ;;
        -D|--device)
            shift 2
            ;;
        -)
            shift
            ;;
        -*)
            shift
            ;;
        *)
            OUT_FILE="$1"
            shift
            ;;
    esac
done

# Ensure PulseAudio is running
if ! pulseaudio --check 2>/dev/null; then
    pulseaudio --start --exit-idle-time=-1 2>/dev/null
fi

# Ensure OpenSL_ES_source is loaded
if ! pactl list sources short 2>/dev/null | grep -q "OpenSL_ES_source"; then
    pactl load-module module-sles-source 2>/dev/null
fi

PA_ARGS=(
    "--rate=${RATE}"
    "--channels=${CHANNELS}"
    "--format=${FORMAT}"
)

if [ "$RAW" = true ]; then
    PA_ARGS+=("--raw")
fi

if pactl list sources short 2>/dev/null | grep -q "OpenSL_ES_source"; then
    PA_ARGS+=("-d" "OpenSL_ES_source")
fi

cleanup() {
    kill -TERM "$PID" 2>/dev/null
    exit 0
}
trap cleanup INT TERM QUIT PIPE

if [ -n "$OUT_FILE" ]; then
    parec "${PA_ARGS[@]}" > "$OUT_FILE" &
else
    parec "${PA_ARGS[@]}" &
fi

PID=$!
wait "$PID" 2>/dev/null
exit 0
```

Make the script executable:
```bash
chmod +x /data/data/com.termux/files/usr/bin/arecord
```

Also sync to `~/.gemini/antigravity-cli/bin/arecord` if the directory exists:
```bash
cp -f /data/data/com.termux/files/usr/bin/arecord ~/.gemini/antigravity-cli/bin/arecord
chmod +x ~/.gemini/antigravity-cli/bin/arecord
```

---

## 4. Verification

Test the bridge using the exact flags that `agy` calls:

```bash
python3 -c '
import subprocess, time, signal

proc = subprocess.Popen(
    ["arecord", "-q", "-f", "S16_LE", "-r", "16000", "-c", "1", "-t", "raw", "-"],
    stdout=subprocess.PIPE,
    stderr=subprocess.PIPE
)

time.sleep(1.0)
proc.send_signal(signal.SIGINT)
stdout, stderr = proc.communicate()
print("Exit code:", proc.returncode)
print("Bytes captured:", len(stdout))
non_zero = sum(1 for b in stdout if b != 0)
print("Non-zero samples:", non_zero)
'
```

**Success criteria**:
- Exit code must be `0`.
- Bytes captured should be ~32,000 bytes per second.
- Non-zero samples should be greater than `0`.

---

## 5. Troubleshooting & Diagnostics

| Symptom | Cause | Solution |
| :--- | :--- | :--- |
| `Bytes captured: 0` or `Stream error: No such entity` | PulseAudio is not running or `OpenSL_ES_source` not loaded | Run `pulseaudio --start --exit-idle-time=-1` and `pactl load-module module-sles-source` |
| `Non-zero samples: 0` (All zeros / silence) | Android microphone permission revoked | Go to **Android Settings → Apps → Termux → Permissions → Microphone → Allow** |
| `stopping the recorder failed: exited unexpectedly` | Wrapper script returned non-zero on interrupt | Ensure `trap cleanup INT TERM QUIT PIPE` exits with `0` upon signal |
| PulseAudio stops after 20 seconds | Default idle timeout in `daemon.conf` | Start PulseAudio with `--exit-idle-time=-1` or set `exit-idle-time = -1` in `/data/data/com.termux/files/usr/etc/pulse/daemon.conf` |
