#!/bin/bash
# ==============================================================================
# MT5 + noVNC Professional Deployment Script (Hardened Version)
# ==============================================================================
set -e

# --- Utility Functions ---
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
warn() { echo -e "\033[1;33m[WARN]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

echo "--------------------------------------------------------"
echo "  MT5 + noVNC Deployment Manager"
echo "--------------------------------------------------------"
echo "Select deployment mode:"
echo "1) Host (Docker Compose - Recommended)"
echo "2) Container (Manual Install - Advanced)"
read -p "Choice [1-2]:, " choice

case $choice in
    1)
        log "Selected: HOST mode. Deploying via Docker Compose..."
        if ! command -v docker &> /dev/null; then err "Docker not found."; fi
        if [ ! -f "docker-compose.yml" ]; then err "docker-compose.yml not found."; fi
        
        read -p "Create MT5 data directory at ~/mt5-data? (y/n): " confirm
        if [ "$confirm" == "y" ]; then 
            mkdir -p ~/mt5-data
            log "Directory created at ~/mt5-data."
        fi

        log "Building and starting container..."
        docker compose up -d --build
        log "Deployment complete. Access at http://<your-ip>:3000/vnc.html"
        ;;
    2)
        log "Selected: CONTAINER mode. Performing manual installation..."
        
        read -p "Create MT5 data directory at /home/abc/mt5-data? (y/n): " confirm
        if [ "$confirm" == "y" ]; then
            mkdir -p /home/abc/mt5-data
            log "Directory created at /home/abc/mt5-data."
        fi

        export DEBIAN_FRONTEND=noninteractive
        dpkg --add-architecture i386
        apt-get update || warn "Apt update failed, attempting to proceed..."
        apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
            wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools novnc websockify tigervnc-standalone-server
        
        if ! id -u abc >/dev/null 2>&1; then
            useradd -m -s /bin/bash abc
            # Ensure sudoers is configured correctly for user abc
            echo "abc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/abc
            chmod 440 /etc/sudoers.d/abc
        fi
        
        # Set VNC password using runuser to avoid sudoers issues in minimal containers
        runuser -u abc -- bash -c "vncpasswd -f <<< 'password'"
        
        # Setup VNC start script with "Clean Sweep" logic
        cat <<EOF > /home/abc/start_vnc.sh
#!/bin/bash
# --- Clean Sweep: Kill existing processes to prevent port clashes ---
pkill -f websockify || true
vncserver -kill :1 2>/dev/null

# Start VNC server
vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None

# Start noVNC proxy
websockify -p 3000 --web /usr/share/novnc localhost:5901 &

# Start Window Manager
DISPLAY=:1 openbox-session &

# Auto-Launch MT5 if binary exists
MT5_PATH="/home/abc/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe"
if [ -f "\$MT5_PATH" ]; then
    echo "🚀 Launching MetaTrader 5..."
    DISPLAY=:1 wine "\$MT5_PATH" &
fi

tail -f ~/.vnc/*.log
EOF
        chmod +x /home/abc/start_vnc.sh
        
        # Final Permission Fix: Ensure all files are owned by abc
        chown -R abc:abc /home/abc/
        
        log "Setup complete. Launching everything automatically..."
        # Use runuser for a guaranteed launch without sudoers dependency
        runuser -u abc -- /home/abc/start_vnc.sh &
        log "VNC, noVNC, and MT5 are now active. Access via port 3000."
        ;;
    *)
        err "Invalid selection."
        ;;
esac
