#!/bin/bash
# ==============================================================================
# start-stream-hls.sh - Dedicated YouTube HLS Ingestion Engine
# Features:
#   - Deterministic .env loading & strict stream key validation (no hardcoded leaks)
#   - Correct 12-hour session rotation (43,200s)
#   - Two-stage graceful process termination (SIGTERM -> SIGKILL)
#   - Active health monitoring (PID status & log modification heartbeat)
#   - Safe execution without eval
# ==============================================================================
set -euo pipefail

# 1. Resolve Script Directory & Load Environment
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        export "$line"
    done < "$ENV_FILE"
fi

# 2. Deterministic Stream Key Extraction (No hardcoded fallback leaks)
STREAM_KEY="${1:-${STREAM_KEY:-}}"
if [ -z "$STREAM_KEY" ]; then
    echo "❌ ERROR: STREAM_KEY is not defined. Set it in .env or pass as argument: ./start-stream-hls.sh <key>" >&2
    exit 1
fi

echo "Starting YouTube HLS stream loop with key: ${STREAM_KEY:0:4}****"

# 3. Graceful Termination Helper
stop_ffmpeg() {
    sudo docker exec mt5-workbench pkill -TERM -f ffmpeg 2>/dev/null || true
    sleep 2
    sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true
}

# Ensure no orphan FFmpeg session exists before initial launch
stop_ffmpeg

# 4. Engine Timing Configuration
MAX_LIFETIME=43200   # Exactly 12 hours in seconds (12 * 60 * 60)
CHECK_INTERVAL=10    # Heartbeat polling rate (seconds)
STALL_TIMEOUT=30     # Max seconds without log update before considering stream frozen
RESTART_BACKOFF=10   # Cool-down wait before restarting stream (seconds)

# 5. Continuous Streaming & Health Supervision Loop
while true; do
    echo "Launching FFmpeg HLS ingest..."

    # Direct execution inside container (no eval, no unneeded xhost +)
    sudo docker exec -u abc -d mt5-workbench bash -c \
        "ffmpeg -nostdin \
        -f x11grab -framerate 24 -video_size 1280x720 -i :1.0 \
        -stream_loop -1 -i /home/abc/audio/BackgroundNocopyright.mp3 \
        -c:v libx264 -preset superfast -tune zerolatency -pix_fmt yuv420p \
        -b:v 5000k -maxrate 5000k -bufsize 10000k -g 48 -flags +cgop \
        -c:a aac -b:a 128k -ar 44100 \
        -f hls -hls_time 2 -hls_list_size 4 -method PUT -http_persistent 1 \
        -hls_segment_filename 'https://a.upload.youtube.com/http_upload_hls?cid=${STREAM_KEY}&copy=0&file=stream_%05d.ts' \
        'https://a.upload.youtube.com/http_upload_hls?cid=${STREAM_KEY}&copy=0&file=stream.m3u8' > /tmp/ffmpeg.log 2>&1"

    START_TIME=$(date +%s)

    # Active Health Check Loop
    while true; do
        sleep "$CHECK_INTERVAL"
        NOW=$(date +%s)

        # Check 1: 12-Hour Forced Rotation
        if (( NOW - START_TIME >= MAX_LIFETIME )); then
            echo "🔄 12-Hour Max Session Lifetime reached. Forcing a clean slate restart..."
            break
        fi

        # Check 2: Process Vitality (Did HLS HTTP connection or FFmpeg drop?)
        if ! sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
            echo "⚠️ FFmpeg process died (HTTP connection closed/failed). Triggering restart..."
            break
        fi

        # Check 3: Log Heartbeat (Is data moving?)
        LAST_MOD=$(sudo docker exec mt5-workbench stat -c %Y /tmp/ffmpeg.log 2>/dev/null || echo 0)
        if (( NOW - LAST_MOD > STALL_TIMEOUT )); then
            echo "⚠️ Stream stalled (Log frozen for >${STALL_TIMEOUT}s). Triggering surgical reset..."
            break
        fi
    done

    # Surgical, graceful cleanup before restart
    echo "Performing cleanup before restart..."
    stop_ffmpeg

    echo "Restarting in ${RESTART_BACKOFF} seconds..."
    sleep "$RESTART_BACKOFF"
done
