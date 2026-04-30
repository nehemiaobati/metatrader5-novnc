#!/bin/bash
# --- MT5 Production Entrypoint ---

# 1. Clean up any stale VNC sessions
vncserver -kill :1 2>/dev/null

# 2. Start VNC server
vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None

# 3. Bridge VNC (Port 5901) to Web (Port 3000) via noVNC
websockify -p 3000 --web /usr/share/novnc localhost:5901 &

# 4. Start the Window Manager
DISPLAY=:1 openbox-session &

# 5. Auto-Launch MT5
# Path is relative to the volume mount /home/abc/.wine
MT5_PATH="/home/abc/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe"
if [ -f "$MT5_PATH" ]; then
    echo "🚀 Launching MetaTrader 5..."
    DISPLAY=:1 wine "$MT5_PATH" &
else
    echo "⚠️ MT5 binary not found at $MT5_PATH."
fi

echo "✅ System Ready. Access via http://<your-ip>:3000/vnc.html"
tail -f ~/.vnc/*.log
