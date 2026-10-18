#!/bin/bash
# ==============================================================================
# MT5 Runtime Manager
# Role: Orchestrate VNC, noVNC, and MetaTrader 5 with deterministic lifecycle
# ==============================================================================
set -e

export DISPLAY=${DISPLAY:-:1}
export USER_NAME=${USER_NAME:-abc}
export HOME_DIR=${HOME_DIR:-/home/$USER_NAME}
export WINEPREFIX=${WINEPREFIX:-$HOME_DIR/.wine}

VNC_PORT=5901
WEB_PORT=3000
MT5_BINARY="$WINEPREFIX/drive_c/Program Files/MetaTrader 5/terminal64.exe"

log()  { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }

# 1. Deterministic Cleanup: Clear stale sessions, display sockets, and locks
log "Cleaning stale sessions and X11 locks..."
pkill -f websockify 2>/dev/null || true
vncserver -kill "$DISPLAY" 2>/dev/null || true
rm -rf /tmp/.X11-unix/X1 /tmp/.X1-lock /tmp/vnc-server-* /tmp/mt5setup.exe

# 2. VNC Password Provisioning: Preserve existing passwords on restart
mkdir -p "$HOME_DIR/.vnc"
if [ ! -f "$HOME_DIR/.vnc/passwd" ]; then
    log "Initializing default VNC password..."
    vncpasswd -f <<< "password" > "$HOME_DIR/.vnc/passwd"
    chmod 600 "$HOME_DIR/.vnc/passwd"
else
    log "Existing VNC password preserved."
fi

# 3. Core Display & Bridge
log "Starting VNC Server on display $DISPLAY..."
vncserver "$DISPLAY" -geometry 1280x720 -depth 24 -localhost no -SecurityTypes VncAuth

log "Starting noVNC Bridge on port $WEB_PORT..."
websockify "$WEB_PORT" --web /usr/share/novnc "localhost:$VNC_PORT" &
WEBSOCKIFY_PID=$!

log "Starting Window Manager..."
openbox-session &
OPENBOX_PID=$!

# 4. MT5 Provisioning & Launch
if [ ! -f "$MT5_BINARY" ]; then
    log "MT5 binary not found. Provisioning fresh installation..."
    wineboot -u
    wget -q https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /tmp/mt5setup.exe
    wine /tmp/mt5setup.exe /auto /silent
    rm -f /tmp/mt5setup.exe

    if [ ! -f "$MT5_BINARY" ]; then
        warn "MT5 installation failed or binary path changed."
    fi
fi

if [ -f "$MT5_BINARY" ]; then
    log "🚀 Launching MetaTrader 5..."
    wine "$MT5_BINARY" &
    MT5_PID=$!
fi

# 5. Graceful Container Shutdown Trap
cleanup() {
    log "Shutting down runtime components..."
    [ -n "$MT5_PID" ] && kill -TERM "$MT5_PID" 2>/dev/null || true
    kill -TERM "$OPENBOX_PID" 2>/dev/null || true
    kill -TERM "$WEBSOCKIFY_PID" 2>/dev/null || true
    vncserver -kill "$DISPLAY" 2>/dev/null || true
    exit 0
}
trap cleanup SIGTERM SIGINT

log "✅ System Ready. Access via http://<your-ip>:$WEB_PORT/vnc.html"

# Deterministic Process Heartbeat Monitor
while true; do
    sleep 5
done
