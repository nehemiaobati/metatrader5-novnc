#!/bin/bash
# ==============================================================================
# stop-stream.sh - Deterministic Stream Cleanup
# ==============================================================================
set -euo pipefail

echo "🛑 Stopping stream processes..."

# 1. Terminate host-side wrapper scripts gracefully
pkill -TERM -f "start-stream(\.sh|-hls\.sh)" 2>/dev/null || true

# 2. Terminate container FFmpeg process (SIGTERM first, then SIGKILL)
sudo docker exec mt5-workbench pkill -TERM -f ffmpeg 2>/dev/null || true
sleep 2
sudo docker exec mt5-workbench pkill -9 -f ffmpeg 2>/dev/null || true

# 3. Force kill host wrappers if still lingering
pkill -9 -f "start-stream(\.sh|-hls\.sh)" 2>/dev/null || true

# 4. Verification Check
WRAPPER_PID=$(pgrep -f "start-stream(\.sh|-hls\.sh)" || true)
CONTAINER_FFMPEG=$(sudo docker exec mt5-workbench pgrep -f ffmpeg 2>/dev/null || true)

if [ -z "$WRAPPER_PID" ] && [ -z "$CONTAINER_FFMPEG" ]; then
    echo "✅ SUCCESS: All stream processes successfully stopped."
else
    [ -n "$WRAPPER_PID" ] && echo "⚠️ Host wrapper still running (PID: $WRAPPER_PID)"
    [ -n "$CONTAINER_FFMPEG" ] && echo "⚠️ Container FFmpeg still running (PID: $CONTAINER_FFMPEG)"
    exit 1
fi
