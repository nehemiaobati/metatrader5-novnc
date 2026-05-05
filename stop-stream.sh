#!/bin/bash
# Kill ffmpeg process inside the container
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null

# Kill any lingering start-stream scripts on the host
# We remove stop-stream.sh from here so the script can finish and exit gracefully
sudo pkill -9 -f start-stream.sh 2>/dev/null || true

# Verify the stream actually stopped
if sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
  echo "❌ Failed to stop stream"
  exit 1
else
  echo "✅ Stream stopped successfully"
fi
