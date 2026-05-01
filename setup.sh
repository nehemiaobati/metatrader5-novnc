#!/bin/bash
# ==============================================================================
# MT5 + noVNC Professional Deployment Script
# ==============================================================================
set -e

# --- Configuration ---
USER_NAME="abc"
DATA_DIR="/home/$USER_NAME/mt5-data"
START_SCRIPT="/home/$USER_NAME/start_vnc.sh"

# --- Utility Functions ---
log() { echo -e "\033[0;32m[INFO]\033[0m $1"; }
err() { echo -e "\033[0;31m[ERROR]\033[0m $1"; exit 1; }

confirm() {
    read -p "$1 (y/n): " choice
    [[ "$choice" =~ ^[Yy]$ ]]
}

# --- Core Logic Functions ---
deploy_host() {
    log "Selected: HOST mode."
    [[ -f "docker-compose.yml" ]] || err "docker-compose.yml not found."
    
    if confirm "Create/Verify MT5 data directory at ~/mt5-data?"; then
        mkdir -p ~/mt5-data
    fi

    docker compose up -d --build
}

deploy_container() {
    log "Selected: CONTAINER mode."
    if confirm "Create/Verify MT5 data directory at $DATA_DIR?"; then
        mkdir -p "$DATA_DIR"
    fi

    install_dependencies
    setup_user
    setup_vnc_auth
    create_start_script
    
    chown -R "$USER_NAME":"$USER_NAME" /home/"$USER_NAME"/
    runuser -u "$USER_NAME" -- "$START_SCRIPT" > /dev/null 2>&1 &
}

install_dependencies() {
    export DEBIAN_FRONTEND=noninteractive
    dpkg --add-architecture i386
    apt-get update -qq
    apt-get install -y -q -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" \
        wine64 wine32 xserver-xorg openbox ffmpeg curl wget sudo net-tools tigervnc-standalone-server websockify
    
    # Download latest noVNC to ensure UI compatibility
    mkdir -p /usr/share/novnc
    wget -qO- https://github.com/novnc/noVNC/archive/refs/tags/v1.4.0.tar.gz | tar -xz -C /usr/share/novnc --strip-components=1
}

setup_user() {
    if ! id -u "$USER_NAME" >/dev/null 2>&1; then
        useradd -m -s /bin/bash "$USER_NAME"
        echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/$USER_NAME"
        chmod 440 "/etc/sudoers.d/$USER_NAME"
    fi
}

setup_vnc_auth() {
    runuser -u "$USER_NAME" -- bash -c "mkdir -p /home/$USER_NAME/.vnc && vncpasswd -f <<< 'password' > /home/$USER_NAME/.vnc/passwd && chmod 600 /home/$USER_NAME/.vnc/passwd"
}
create_start_script() {
    cat <<'EOF' > "$START_SCRIPT"
#!/bin/bash
# --- Automated MT5 Provisioning ---
export DISPLAY=:1
export USER=abc
export HOME=/home/abc
export WINEPREFIX=/home/abc/.wine

pkill -f websockify || true
vncserver -kill :1 2>/dev/null || true
rm -rf /tmp/.X11-unix/X1 || true

vncserver :1 -geometry 1280x720 -depth 24 -localhost no -SecurityTypes None
websockify 3000 --web /usr/share/novnc localhost:5901 &
openbox-session &

# Path checked in the standard Wine prefix
MT5_PATH="/home/abc/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe"

# If binary is missing, attempt silent install without overwriting existing data
if [ ! -f "$MT5_PATH" ]; then
    echo "Binary not found. Preparing Wine environment..."
    wineboot -u
    if [ ! -f "/tmp/mt5setup.exe" ]; then
        wget -q https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe -O /tmp/mt5setup.exe
    fi
    echo "Installing MT5 silently..."
    wine /tmp/mt5setup.exe /auto /silent
fi

# Launch MT5
[ -f "$MT5_PATH" ] && wine "$MT5_PATH" &

tail -f /home/abc/.vnc/*.log
EOF
    chmod +x "$START_SCRIPT"
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
