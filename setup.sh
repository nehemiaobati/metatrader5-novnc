#!/bin/bash
# ==============================================================================
# MT5 + noVNC Interactive Deployment Script
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
read -p "Choice [1-2]: " choice

case $choice in
    1)
        log "Selected: HOST mode. Deploying via Docker Compose..."
        if ! command -v docker &> /dev/null; then err "Docker not found."; fi
        if [ ! -f "docker-compose.yml" ]; then err "docker-compose.yml not found."; fi
        
        read -p "Create MT5 data directory at ~/mt5-data? (y/n): " confirm
        if [ "$confirm" == "y" ]; then mkdir -p ~/mt5-data; fi

        log "Building and starting container..."
        docker compose up -d --build
        log "Deployment complete. Access at http://<your-ip>:3000/vnc.html"
        ;;
    2)
        log "Selected: CONTAINER mode. Performing manual installation..."
        export DEBIAN_FRONTEND=noninteractive
        dpkg --add-architecture i386
        apt-get update
        apt-get install -y -o Dpkg::Options::="--force-confdef" \
            wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools novnc websockify tigervnc-standalone-server
        
        if ! id -u abc >/dev/null 2>&1; then
            useradd -m -s /bin/bash abc
            echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
        fi
        
        sudo -u abc vncpasswd -f <<< "password"
        
        # Setup VNC start script
        cat <<EOF > /home/abc/start_vnc.sh
#!/bin/bash
vncserver -kill :1 2>/dev/null
vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None
websockify -p 3000 --web /usr/share/novnc localhost:5901 &
DISPLAY=:1 openbox-session &
tail -f ~/.vnc/*.log
EOF
        chmod +x /home/abc/start_vnc.sh
        chown -R abc:abc /home/abc/
        
        log "Setup complete. Launching services automatically..."
        sudo -u abc /home/abc/start_vnc.sh &
        log "VNC and noVNC are now active. Access via port 3000."
        ;;
    *)
        err "Invalid selection."
        ;;
esac
