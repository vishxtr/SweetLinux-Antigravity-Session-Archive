#!/data/data/com.termux/files/usr/bin/bash
# ==============================================================================
# setup-voice.sh - Enable / Repair Voice Input (/voice) in Antigravity CLI on Termux
# ==============================================================================
set -euo pipefail

TERMUX_PREFIX="/data/data/com.termux/files/usr"
PULSE_CONFIG="${TERMUX_PREFIX}/etc/pulse/default.pa"
ARECORD_BIN="${TERMUX_PREFIX}/bin/arecord"
AGY_BIN_DIR="${HOME}/.gemini/antigravity-cli/bin"

echo "=== [1/5] Checking dependencies ==="
if ! command -v pulseaudio >/dev/null 2>&1 || ! command -v parec >/dev/null 2>&1; then
    echo "[!] PulseAudio not found. Installing pulseaudio..."
    pkg install -y pulseaudio
fi

echo "=== [2/5] Configuring PulseAudio OpenSL ES Source ==="
if [ ! -f "$PULSE_CONFIG" ]; then
    echo "[ERROR] PulseAudio config not found at $PULSE_CONFIG"
    exit 1
fi

# Ensure module-sles-source is configured
if ! grep -q "load-module module-sles-source" "$PULSE_CONFIG"; then
    echo "[+] Adding module-sles-source to $PULSE_CONFIG..."
    sed -i '/load-module module-sles-sink/a load-module module-sles-source\nset-default-source OpenSL_ES_source' "$PULSE_CONFIG"
else
    echo "[✓] module-sles-source already configured in $PULSE_CONFIG"
fi

echo "=== [3/5] Installing arecord Compatibility Bridge ==="
# Backup original symlink/binary if not already backed up
if [ -L "$ARECORD_BIN" ] && [ ! -e "${ARECORD_BIN}.alsa" ]; then
    cp -P "$ARECORD_BIN" "${ARECORD_BIN}.alsa"
fi

cat << 'EOF' > "$ARECORD_BIN"
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
EOF

chmod +x "$ARECORD_BIN"

# Sync to antigravity-cli/bin if directory exists
if [ -d "$AGY_BIN_DIR" ]; then
    cp -f "$ARECORD_BIN" "${AGY_BIN_DIR}/arecord"
    chmod +x "${AGY_BIN_DIR}/arecord"
fi
echo "[✓] arecord bridge installed."

echo "=== [4/5] Restarting PulseAudio ==="
pulseaudio -k 2>/dev/null || true
sleep 0.5
pulseaudio --start --exit-idle-time=-1 2>/dev/null || true

# Verify source
if pactl list sources short 2>/dev/null | grep -q "OpenSL_ES_source"; then
    echo "[✓] OpenSL_ES_source is active."
else
    echo "[!] Attempting manual module load..."
    pactl load-module module-sles-source 2>/dev/null || true
fi

echo "=== [5/5] Testing audio capture ==="
TMP_DIR="${TMPDIR:-/data/data/com.termux/files/usr/tmp}"
mkdir -p "$TMP_DIR"
TEST_FILE="${TMP_DIR}/voice_test_$$.raw"
parec -d OpenSL_ES_source --raw --channels=1 --rate=16000 --format=s16le > "$TEST_FILE" 2>/dev/null &
TEST_PID=$!
sleep 0.8
kill -TERM "$TEST_PID" 2>/dev/null || true
wait "$TEST_PID" 2>/dev/null || true

if [ -f "$TEST_FILE" ]; then
    FILE_SIZE=$(wc -c < "$TEST_FILE")
    rm -f "$TEST_FILE"
    if [ "$FILE_SIZE" -gt 1000 ]; then
        echo "[✓] Audio capture successful! Captured $FILE_SIZE bytes."
        echo "=== Setup complete! You can now use /voice in Antigravity CLI ==="
    else
        echo "[WARNING] Recorded file is very small ($FILE_SIZE bytes)."
        echo "Check that Termux has Microphone permissions in Android Settings -> Apps -> Termux -> Permissions."
    fi
else
    echo "[!] Test recording failed. Please check Android microphone permissions."
fi
