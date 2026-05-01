# MetaTrader 5 + noVNC Deployment

This repository provides a professional, automated solution for running MetaTrader 5 in a headless Linux environment, accessible via a web browser using noVNC.

## 🌟 Architecture
- **Environment**: Optimized Ubuntu 22.04 base.
- **Desktop**: Lightweight `Openbox` Window Manager.
- **Access**: `TigerVNC` bridged to web via `noVNC` (Port 3000).
- **Deployment**: `setup.sh` provides a modular, automated interface for Host or Container deployment.

## 🚀 Usage

Run the deployment script and choose your preferred method:
```bash
bash setup.sh
```

### 1. Host Deployment (Recommended)
Uses Docker Compose for permanent, scalable trading environments.
*   **Requirement**: Docker installed.
*   **Workflow**: Creates/verifies a local `~/mt5-data` directory and builds the container.

### 2. Manual Container Deployment (Advanced)
Installs and configures all required services directly inside a running container.
*   **Workflow**: Handles dependency installation, user management, and service orchestration automatically.

## 📂 Data Management
Your MT5 configuration is mapped to the `mt5-data` directory. 
- **Persistence**: For existing environments, place your `.wine` folder into `mt5-data/`.
- **Initialization**: If the environment is clean, the system guides you to initialize the wine environment and install the MT5 binary via VNC.

## 🛡️ Security
- **Port 3000**: Used for noVNC browser access (`http://<your-ip>:3000/vnc.html`).
