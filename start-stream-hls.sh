#!/bin/bash
# start-stream.sh - HLS Active Health Check + 12-Hour Rotation

# Load STREAM_KEY from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

STREAM_KEY="${STREAM_KEY:-${1:-1jj6-rze2-dxy9-1xgq-964m}}"
echo "Starting YouTube HLS stream loop with key: $STREAM_KEY"

# Ensure we aren't already running
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true

# Infinite loop to keep the stream alive
while true; do
    echo "Launching FFmpeg HLS ingest..."
    
    CMD="sudo docker exec -u abc -d mt5-workbench bash -c \"export DISPLAY=:1 && xhost + && ffmpeg \
    -f x11grab -framerate 24 -video_size 1280x720 -i :1.0 \
    -stream_loop -1 -i /home/abc/audio/BackgroundNocopyright.mp3 \
    -c:v libx264 -preset superfast -tune zerolatency -pix_fmt yuv420p \
    -b:v 5000k -maxrate 5000k -bufsize 10000k -g 48 -flags +cgop \
    -c:a aac -b:a 128k -ar 44100 \
    -f hls -hls_time 2 -hls_list_size 4 -method PUT -http_persistent 1 \
    -hls_segment_filename 'https://a.upload.youtube.com/http_upload_hls?cid=$STREAM_KEY&copy=0&file=stream_%05d.ts' \
    'https://a.upload.youtube.com/http_upload_hls?cid=$STREAM_KEY&copy=0&file=stream.m3u8' >>/tmp/ffmpeg.log 2>&1\""
    
    eval $CMD

    # --- SESSION TIMER SETUP ---
    START_TIME=$(date +%s)
    MAX_LIFETIME=3600  # 12 hours in seconds (12 * 60 * 60)

    # --- ACTIVE HEALTH CHECK ---
    while true; do
        sleep 10  # Check every 10 seconds
        NOW=$(date +%s)
        
        # Check 1: 12-Hour Forced Rotation
        if (( NOW - START_TIME > MAX_LIFETIME )); then
            echo "🔄 12-Hour Max Session Lifetime reached. Forcing a clean slate restart..."
            break
        fi

        # Check 2: PID Check (Did HLS connection fail?)
        if ! sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
            echo "⚠️ FFmpeg process died (HTTP connection closed/failed). Triggering restart..."
            break
        fi

        # Check 3: Log Heartbeat (Is data moving?)
        LAST_MOD=$(sudo docker exec mt5-workbench stat -c %Y /tmp/ffmpeg.log 2>/dev/null || echo 0)
        if (( NOW - LAST_MOD > 30 )); then
            echo "⚠️ Stream stalled (Log frozen). Triggering surgical reset..."
            break
        fi
    done

    # Surgical Cleanup: Kill everything to ensure a fresh YouTube handshake
    echo "Performing total cleanup before restart..."
    sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true
    
    # Wait 10 seconds to let YouTube recognize the stream ended before starting again
    echo "Restarting in 10 seconds..."
    sleep 60
done
