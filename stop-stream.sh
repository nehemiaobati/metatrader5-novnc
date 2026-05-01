#!/bin/bash
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null
sudo killall -9 start-stream.sh stop-stream.sh 2>/dev/null || true
if sudo docker exec mt5-workbench pgrep -f ffmpeg >/dev/null; then
  echo "Failed to stop stream"
  exit 1
else
  echo "Stream stopped"
fi
