#!/bin/bash
# ==============================================================================
# MT5 Runtime Manager
# Role: Orchestrate VNC, noVNC, and MetaTrader 5
# ==============================================================================

# --- Environment Setup ---
# Use provided variables or defaults to avoid "braiding" with specific users
export DISPLAY=${DISPLAY:-:1}
export USER_NAME=${USER_NAME:-abc}
export HOME_DIR=${HOME_DIR:-/home/$USER_NAME}
export WINEPREFIX=${WINEPREFIX:-$HOME_DIR/.wine}

# --- Constants ---
VNC_PORT=5901
WEB_PORT=3000
MT5_BINARY="$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe"

log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# 1. Clean State: Remove remnants of previous crashes to prevent port clashes
log "Cleaning stale sessions..."
pkill -f websockify || true
vncserver -kill :1 2>/dev/null || true
rm -rf /tmp/.X11-unix/X1 /tmp/vnc-server-*

# 2. VNC Server: The core display layer
# Alternative (Insecure): vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes None --I-KNOW-THIS-IS-INSECURE
log "Starting VNC Server..."
vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth

# 3. Web Bridge: Expose VNC to browser
log "Starting noVNC Bridge on port $WEB_PORT..."
websockify $WEB_PORT --web /usr/share/novnc localhost:$VNC_PORT &

# 4. Desktop Environment: Basic Window Management
log "Starting Window Manager..."
openbox-session &

# 5. MT5 Provisioning & Launch
if [ ! -f "$MT5_BINARY" ]; then
    log "MT5 binary not found. Provisioning fresh installation..."
    wineboot -u
    wget -q https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /tmp/mt5setup.exe
    wine /tmp/mt5setup.exe /auto /silent
    
    if [ ! -f "$MT5_BINARY" ]; then
        warn "MT5 installation failed or binary path changed."
    fi
fi

if [ -f "$MT5_BINARY" ]; then
    log "🚀 Launching MetaTrader 5..."
    wine "$MT5_BINARY" &
fi

log "✅ System Ready. Access via http://<your-ip>:$WEB_PORT/vnc.html"
tail -f "$HOME_DIR/.vnc/*.log"
