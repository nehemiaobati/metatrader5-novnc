#!/bin/bash
# start-stream.sh

# Load STREAM_KEY from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

STREAM_KEY="${STREAM_KEY:-${1:-zmtb-7xv1-x9jb-bhg8-2rur}}"

echo "Starting YouTube stream loop with key: $STREAM_KEY"

# Ensure we aren't already running
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true

# Infinite loop to keep the stream alive
while true; do
    echo "Launching FFmpeg ingest..."
    CMD="sudo docker exec -u abc -d mt5-workbench bash -c \"export DISPLAY=:1 && xhost + && ffmpeg \
    -f x11grab -framerate 24 -video_size 1280x720 -i :1.0 \
    -stream_loop -1 -i /home/abc/audio/BackgroundNocopyright.mp3 \
    -c:v libx264 -preset superfast -tune zerolatency -pix_fmt yuv420p \
    -b:v 5000k -maxrate 5000k -bufsize 10000k -g 48 \
    -c:a aac -b:a 128k -ar 44100 \
    -f flv rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY >>/tmp/ffmpeg.log 2>&1\""
    echo "Executing: $CMD"
    eval $CMD

    # Wait for the process to exit or fail
    while sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; do
        sleep 5
    done

    echo "Stream disconnected. Restarting in 5 seconds..."
    sleep 5
done
