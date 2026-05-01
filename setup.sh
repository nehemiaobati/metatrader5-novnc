#!/bin/bash
# ==============================================================================
# MT5 + noVNC Deployment Manager
# Role: Environment Provisioning & Orchestration
# ==============================================================================
set -e

# --- Configuration ---
USER_NAME="abc"
DATA_DIR="/home/$USER_NAME/mt5-data"
RUNTIME_SCRIPT="/home/$USER_NAME/start_vnc.sh"

# --- Utility Functions ---
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

confirm() {
    read -p "$1 (y/n): " choice
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        return 0
    else
        log "User opted NOT to create/overwrite data directory."
        return 1
    fi
}

# --- Logic Modules ---
install_dependencies() {
    log "Installing core dependencies..."
    export DEBIAN_FRONTEND=noninteractive
    dpkg --add-architecture i386
    apt-get update -qq
    apt-get install -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools tigervnc-standalone-server websockify
    
    mkdir -p /usr/share/novnc
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xz -C /usr/share/novnc --strip-components=1
    echo "<meta http-equiv=\"refresh\" content=\"0; url=/vnc.html\">" > /usr/share/novnc/index.html
}

setup_user() {
    if ! id -u "$USER_NAME" >/dev/null 2>&1; then
        log "Creating user $USER_NAME..."
        useradd -m -s /bin/bash "$USER_NAME"
        echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
        chmod 440 "/etc/sudoers.d/$USER_NAME"
    fi
}

deploy_host() {
    log "Selected: HOST mode (Docker Compose)."
    [[ -f "docker-compose.yml" ]] || err "docker-compose.yml not found."
    
    if confirm "Create/Verify MT5 data directory at ~/mt5-data?"; then
        mkdir -p ~/mt5-data
    fi

    docker compose up -d --build
}

deploy_container() {
    log "Selected: CONTAINER mode (Manual Install)."
    
    if confirm "Initialize MT5 data directory at $DATA_DIR?"; then
        mkdir -p "$DATA_DIR"
    fi

    install_dependencies
    setup_user
    
    # Simple: Copy the unified runtime script instead of regenerating it
    log "Deploying runtime manager..."
    cp entrypoint.sh "$RUNTIME_SCRIPT"
    chmod +x "$RUNTIME_SCRIPT"
    
    # Set VNC password
    runuser -u "$USER_NAME" -- bash -c "mkdir -p ~/.vnc && vncpasswd -f <<< 'password' > ~/.vnc/passwd && chmod 600 ~/.vnc/passwd"
    
    chown -R "$USER_NAME":"$USER_NAME" /home/"$USER_NAME"/
    runuser -u "$USER_NAME" -- "$RUNTIME_SCRIPT" > /dev/null 2>&1 &
}

# --- Main Entry ---
echo "--------------------------------------------------------"
echo "  MT5 + noVNC Deployment Manager"
echo "--------------------------------------------------------"
echo "1) Host (Docker Compose)"
echo "2) Container (Manual Install)"
read -p "Choice [1-2]: " choice

case $choice in
    1) deploy_host ;;
    2) deploy_container ;;
    *) err "Invalid selection." ;;
esac

log "Deployment complete. Access at http://<your-ip>:3000/vnc.html"
