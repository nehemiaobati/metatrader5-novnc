#!/bin/bash
set -e

# Load STREAM_KEY from .env if it exists
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Use .env value, fallback to argument, fallback to hardcoded default
STREAM_KEY="${STREAM_KEY:-${1:-zmtb-7xv1-x9jb-bhg8-2rur}}"

echo "Starting YouTube stream with key: $STREAM_KEY"

# Stop any existing ffmpeg processes inside the container
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true
sleep 1

# Start streaming: Loops the mp3 file and captures the screen
# -u abc: Run as the VNC user to access X11
# xhost +: Disable access control to allow FFmpeg to capture the screen
sudo docker exec -u abc -d mt5-//workbench bash -c "export DISPLAY=:1 && xhost + && ffmpeg \
-f x11grab -framerate 24 -video_size 1280x720 -i :1.0 \
-stream_loop -1 -i /home/abc/audio/BackgroundNocopyright.mp3 \
-c:v libx264 -preset superfast -tune zerolatency -pix_fmt yuv420p \
-b:v 5000k -maxrate 5000k -bufsize 10000k -g 48 \
-c:a aac -b:a 128k -ar 44100 \
-f flv rtmp://a.rtmp.youtube.com/live2/$STREAM_KEY 2>>/tmp/ffmpeg.log"

sleep 2

# Check if the process is running
if sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
  echo "Stream started successfully"
  echo "Logs: sudo docker exec mt5-workbench tail -f /tmp/ffmpeg.log"
else
  echo "Failed to start stream. Check the logs below:"
  sudo docker exec mt5-workbench tail -20 /tmp/ffmpeg.log || true
  exit 1
fi
