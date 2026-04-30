#!/bin/bash
# ==============================================================================
# METATRADER 5 + noVNC AUTOMATED SETUP SCRIPT
# ==============================================================================
# This script is designed to work in two modes:
# 1. Host Mode: Deploys the environment using Docker Compose.
# 2. Container Mode: Installs dependencies manually inside a running container.
# ==============================================================================

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
err() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo "----------------------------------------------------------------"
echo "  MT5 + noVNC Deployment Manager"
echo "----------------------------------------------------------------"

# Check if running inside a container
if [ -f /.dockerenv ]; then
    MODE="container"
else
    MODE="host"
fi

log "Detected Mode: $MODE"

if [ "$MODE" == "host" ]; then
    log "Operating in HOST mode. Deploying via Docker Compose..."
    
    if ! command -v docker &> /dev/null; then
        err "Docker is not installed. Please install Docker and Docker Compose first."
    fi

    # Check for docker-compose.yml
    if [ ! -f "docker-compose.yml" ]; then
        err "docker-compose.yml not found in current directory."
    fi

    echo "🚀 Building and starting the MT5 container..."
    docker compose up -d --build
    
    log "Deployment successful! Access your VNC at http://<VPS-IP>:3000/vnc.html"

else
    log "Operating in CONTAINER mode. Performing manual installation..."
    
    # Force non-interactive
    export DEBIAN_FRONTEND=noninteractive

    log "Updating package lists and adding i386 architecture..."
    dpkg --add-architecture i386
    apt-get update

    log "Installing system dependencies (Wine, noVNC, TigerVNC)..."
    apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools novnc websockify tigervnc-standalone-server

    log "Configuring VNC environment..."
    # Check if user 'abc' exists, if not create them
    if ! id -u abc >/dev/null 2>&1; then
        useradd -m -s /bin/bash abc
        echo "abc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers
    fi

    # Set up VNC password for user abc
    sudo -u abc vncpasswd -f <<< "password"
    
    log "Setting up startup script..."
    # Create the start script inside the container
    cat <<EOF > /home/abc/start_vnc.sh
#!/bin/bash
vncserver -kill :1 2>/dev/null
vncserver :1 -geometry 1280x720 -depth 24 -SecurityTypes None
websockify -p 3000 --web /usr/share/novnc localhost:5901 &
DISPLAY=:1 openbox-session &
echo "VNC and noVNC are now running on port 3000!"
tail -f ~/.vnc/*.log
EOF
    chmod +x /home/abc/start_vnc.sh
    chown -R abc:abc /home/abc/

    log "Manual installation complete!"
    echo "🚀 To start the environment, run: sudo -u abc /home/abc/start_vnc.sh"
fi

echo "----------------------------------------------------------------"
echo "  Process Finished Successfully"
echo "----------------------------------------------------------------"
