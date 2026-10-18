#!/bin/bash
# ==============================================================================
# start-stream.sh - Unified YouTube Ingestion Engine (RTMP / HLS)
# Usage: ./start-stream.sh [--rtmp | --hls] [STREAM_KEY]
# ==============================================================================
set -euo pipefail

MODE="rtmp"
if [[ "${1:-}" == "--hls" ]]; then
    MODE="hls"
    shift
elif [[ "${1:-}" == "--rtmp" ]]; then
    MODE="rtmp"
    shift
fi

# Locate project root relative to script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_FILE="$SCRIPT_DIR/.env"

if [ -f "$ENV_FILE" ]; then
    # Deterministically export non-commented, non-empty environment variables
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^#.*$ || -z "$line" ]] && continue
        export "$line"
    done < "$ENV_FILE"
fi

STREAM_KEY="${1:-${STREAM_KEY:-}}"
if [ -z "$STREAM_KEY" ]; then
    echo "❌ ERROR: STREAM_KEY is not defined. Set it in .env or pass as argument." >&2
    exit 1
fi

echo "Starting YouTube $MODE stream loop with key: ${STREAM_KEY:0:4}****"

stop_ffmpeg() {
    sudo docker exec mt5-workbench pkill -TERM -f ffmpeg 2>/dev/null || true
    sleep 2
    sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true
}

# Ensure no orphan FFmpeg is running
stop_ffmpeg

MAX_LIFETIME=43200  # Exactly 12 hours in seconds (12 * 60 * 60)
CHECK_INTERVAL=10
STALL_TIMEOUT=30
RESTART_BACKOFF=10

while true; do
    echo "Launching FFmpeg $MODE ingest..."

    if [ "$MODE" = "hls" ]; then
        OUTPUT_ARGS=(
            -f hls -hls_time 2 -hls_list_size 4 -method PUT -http_persistent 1
            -hls_segment_filename "https://a.upload.youtube.com/http_upload_hls?cid=${STREAM_KEY}&copy=0&file=stream_%05d.ts"
            "https://a.upload.youtube.com/http_upload_hls?cid=${STREAM_KEY}&copy=0&file=stream.m3u8"
        )
    else
        OUTPUT_ARGS=(
            -f flv "rtmp://a.rtmp.youtube.com/live2/${STREAM_KEY}"
        )
    fi

    # Launch containerized FFmpeg without unsafe eval expansion
    sudo docker exec -u abc -d mt5-workbench bash -c \
        "ffmpeg -nostdin \
        -f x11grab -framerate 24 -video_size 1280x720 -i :1.0 \
        -stream_loop -1 -i /home/abc/audio/BackgroundNocopyright.mp3 \
        -c:v libx264 -preset superfast -tune zerolatency -pix_fmt yuv420p \
        -b:v 5000k -maxrate 5000k -bufsize 10000k -g 48 -flags +cgop \
        -c:a aac -b:a 128k -ar 44100 \
        ${OUTPUT_ARGS[*]} > /tmp/ffmpeg.log 2>&1"

    START_TIME=$(date +%s)

    # Active Health Check
    while true; do
        sleep "$CHECK_INTERVAL"
        NOW=$(date +%s)

        # Check 1: 12-Hour Rotation
        if (( NOW - START_TIME >= MAX_LIFETIME )); then
            echo "🔄 12-Hour Max Session Lifetime reached. Rotating stream..."
            break
        fi

        # Check 2: Process Vitality
        if ! sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
            echo "⚠️ FFmpeg process exited unexpectedly. Triggering restart..."
            break
        fi

        # Check 3: Log Activity Heartbeat
        LAST_MOD=$(sudo docker exec mt5-workbench stat -c %Y /tmp/ffmpeg.log 2>/dev/null || echo 0)
        if (( NOW - LAST_MOD > STALL_TIMEOUT )); then
            echo "⚠️ Stream output stalled for >${STALL_TIMEOUT}s. Triggering reset..."
            break
        fi
    done

    echo "Terminating current FFmpeg session..."
    stop_ffmpeg

    echo "Restarting in ${RESTART_BACKOFF} seconds..."
    sleep "$RESTART_BACKOFF"
done
