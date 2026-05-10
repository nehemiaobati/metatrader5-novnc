#!/bin/bash
# stop-stream.sh - Surgical Cleanup

echo "🛑 Stopping project-specific stream components..."

# 1. Kill the specific host-side wrapper loops
# We target the exact filenames found in your directory
echo "Terminating wrappers..."
sudo pkill -9 -f "[s]tart-stream.sh" 2>/dev/null || true
sudo pkill -9 -f "[s]tart-stream-hls.sh" 2>/dev/null || true

# 2. Kill FFmpeg inside the specific docker container
echo "Terminating FFmpeg in container..."
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true

# 3. Final Verification
echo "Verifying cleanup..."

# Check for the specific wrapper scripts
WRAPPER_RTMP=$(pgrep -f "start-stream.sh")
WRAPPER_HLS=$(pgrep -f "start-stream-hls.sh")
# Check for FFmpeg inside the container
CONTAINER_FFMPEG=$(sudo docker exec mt5-workbench pgrep -f ffmpeg 2>/dev/null)

if [ -z "$WRAPPER_RTMP" ] && [ -z "$WRAPPER_HLS" ] && [ -z "$CONTAINER_FFMPEG" ]; then
  echo "✅ SUCCESS: Project processes stopped. Total Zero reached."
else
  echo "⚠️ WARNING: Some processes are still lingering."
  [ ! -z "$WRAPPER_RTMP" ] && echo " -> RTMP Wrapper active (PID: $WRAPPER_RTMP)"
  [ ! -z "$WRAPPER_HLS" ]  && echo " -> HLS Wrapper active (PID: $WRAPPER_HLS)"
  [ ! -z "$CONTAINER_FFMPEG" ] && echo " -> FFmpeg active in Docker (PID: $CONTAINER_FFMPEG)"
fi
