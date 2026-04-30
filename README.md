# MetaTrader 5 + noVNC Deployment

This repository provides a professional, automated solution for running MetaTrader 5 in a headless Linux environment, accessible via a web browser using noVNC.

## 🌟 Architecture
- **Environment**: Optimized Ubuntu 22.04 base.
- **Desktop**: Lightweight `Openbox` Window Manager.
- **Access**: `TigerVNC` bridged to web via `noVNC` (Port 3000).
- **Deployment**: `setup.sh` handles both Docker-based (host) and manual (container) installations.

## 🚀 Usage

### 1. Host Deployment (Recommended)
This method is fully automated and recommended for permanent trading environments.

```bash
git clone https://github.com/nehemiaobati/metatrader5-novnc.git
cd metatrader5-novnc
bash setup.sh
```
*The script will automatically create the `~/mt5-data` directory and build the container.*

### 2. Manual Container Deployment
Use this method only if you are already inside a container and want a quick setup.
```bash
git clone https://github.com/nehemiaobati/metatrader5-novnc.git
cd metatrader5-novnc
bash setup.sh
# Follow the prompts...
```

## 📂 Data Management
Your MT5 data is mapped to the `mt5-data` directory. 
- **Important**: To persist your trading configuration, place your existing `.wine` folder into `mt5-data/`.
- The system expects: `mt5-data/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe`

## 🛡️ Security
- **Default VNC Password**: `password` (Change via `vncpasswd` inside).
- **Port 3000**: Used for noVNC browser access. Ensure this port is open on your firewall.
