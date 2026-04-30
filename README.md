# MetaTrader 5 + noVNC Automated Deployment

A professional, streamlined deployment for running MetaTrader 5 in a headless Linux environment with a web-accessible VNC interface.

## 🌟 Features
- **Low Resource**: Uses `Openbox` window manager for minimal RAM usage.
- **Browser Access**: Integrated `noVNC` allows access via port 3000 without a VNC client.
- **Auto-Launch**: The system automatically boots VNC, the proxy, and launches MT5 on startup.
- **Persistent Data**: Maps host volume to avoid data loss on container restart.
- **Hybrid Setup**: Supports both full Docker builds and manual internal container installation.

## 🚀 Quick Start

### Method 1: Host Deployment (Recommended)
If you are on your VPS host, use Docker Compose to deploy the entire stack:

\`\`\`bash
git clone https://github.com/nehemiaobati/metatrader5-novnc.git
cd metatrader5-novnc
docker compose up -d --build
\`\`\`
Access the interface at: \`http://<your-vps-ip>:3000/vnc.html\`

### Method 2: Manual Container Installation
If you are already inside a running Ubuntu container and want to set up the MT5 environment manually:

\`\`\`bash
git clone https://github.com/nehemiaobati/metatrader5-novnc.git
cd metatrader5-novnc
bash setup.sh
\`\`\`
Once the script finishes, launch the services:
\`\`\`bash
sudo -u abc /home/abc/start_vnc.sh
\`\`\`

## 📂 Folder Structure
- \`setup.sh\`: The master installation manager (works for both Host and Container modes).
- \`Dockerfile\`: The blueprint for the production image.
- \`entrypoint.sh\`: The internal boot sequence.
- \`docker-compose.yml\`: Orchestration for deployment.

## ⚙️ Configuration
- **VNC Port**: 5901
- **Web Port**: 3000
- **User**: \`abc\`
- **VNC Password**: \`password\` (Change this via \`vncpasswd\` inside the container).

## 🛡️ Security Note
This setup uses \`network_mode: host\` for optimal trading performance. Ensure your VPS firewall allows traffic on port 3000.
