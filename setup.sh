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
echo "  MT5 + noVNC Interactive Deployment"
echo "--------------------------------------------------------"

# --- Detect Environment ---
if [ -f /.dockerenv ]; then
    MODE="container"
else
    MODE="host"
fi

# --- Host Mode ---
if [ "$MODE" == "host" ]; then
    log "Detected: HOST environment."
    read -p "Create MT5 data directory at ~/mt5-data? (y/n): " confirm
    if [ "$confirm" == "y" ]; then
        mkdir -p ~/mt5-data
        log "Directory created at ~/mt5-data."
    fi

    log "Building Docker image..."
    docker compose up -d --build
    log "Deployment complete. Access at http://<your-ip>:3000/vnc.html"

# --- Container Mode ---
else
    warn "Detected: CONTAINER environment. (Production use on host is recommended)"
    read -p "Proceed with manual installation? (y/n): " confirm
    if [ "$confirm" != "y" ]; then exit 0; fi

    log "Installing dependencies..."
    dpkg --add-architecture i386
    apt-get update && apt-get install -y -o Dpkg::Options::="--force-confdef" \
        wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools novnc websockify tigervnc-standalone-server
    
    # Create user
    if ! id -u abc >/dev/null 2>&1; then
        useradd -m -s /bin/bash abc
        echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    fi
    
    log "Setup complete. Run /home/abc/start_vnc.sh to launch."
fi
