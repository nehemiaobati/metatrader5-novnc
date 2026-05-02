# MetaTrader 5 + noVNC Production Suite

A professional, automated solution for deploying MetaTrader 5 in a headless Linux environment, accessible via any modern web browser using noVNC.

## 🌟 System Architecture
- **OS Base**: Ubuntu 22.04 / 24.04.
- **Desktop**: Lightweight `Openbox` Window Manager.
- **VNC Server**: `TigerVNC` (Port 5901).
- **Web Bridge**: `noVNC` + `Websockify` (Port 3000).
- **Orchestration**: Unified deployment via `setup.sh` supporting both Dockerized and Manual environments.

---

## 🚀 Quick Start

1. **Clone the repository:**
   ```bash
   git clone https://github.com/nehemiaobati/metatrader5-novnc.git
   cd metatrader5-novnc
   ```

2. **Run the deployment wizard:**
   ```bash
   bash setup.sh
   ```
   *Follow the prompts to choose between **Host Mode** (Recommended) or **Container Mode**.*

3. **Access the Terminal:**
   Open your browser and navigate to:
   `http://<your-server-ip>:3000/vnc.html`

---

## 📖 Operations Manual

### 1. Deployment Modes

#### **Host Mode (Docker Compose)**
Best for production. It uses Docker to isolate the environment while keeping your MT5 data on the host machine.
- **Persistence**: Data is stored in `~/mt5-data`.
- **Management**: Uses `docker compose` for lifecycle management.

#### **Container Mode (Manual)**
Best for environments where you are already inside a basic Ubuntu container.
- **Provisioning**: `setup.sh` installs all dependencies (Wine, Xvnc, noVNC) directly into the running container.
- **Execution**: Launches the services as the user `abc`.

### 2. Access & Security

#### **VNC Authentication**
To prevent unauthorized access, the VNC server requires a password.

- **Default Password:** `password`

#### **Changing the Password**
There are two ways to manage the password depending on when you want to change it:

**A. Before Initial Deployment (Setting a Custom Default)**
If you want a different password from the start, you can customize it based on your deployment mode:
- **Host Mode:** Edit the `Dockerfile`. Find the line `RUN bash -c 'sudo -u abc vncpasswd -f <<< "password"'` and replace `"password"` with your desired password.
- **Container Mode:** Edit `setup.sh`. Find the line containing `vncpasswd -f <<< 'password'` and replace `'password'` with your desired password.

*(Note: Passwords must be at least 6 characters long.)*

**B. On a Running System (Updating Password)**
To change the password while the system is active, run:
```bash
sudo docker exec -it -u abc mt5-workbench vncpasswd
```

⚠️ **CRITICAL:** Password changes are **not instant**. The VNC server loads the password into memory at startup. To apply your new password, you **must** restart the VNC session. 

**The simplest way to apply the change is to restart the container:**
```bash
sudo docker restart mt5-workbench
```
*Once restarted, the VNC server will load the new password from the disk.*


### 3. Streaming Management
The suite includes a professional streaming module to broadcast your MT5 terminal to YouTube.

**Configuration:**
Create a `.env` file in the project root:
```env
STREAM_KEY=your_youtube_stream_key_here
```

**Controls:**
- **Start Stream:** `bash start-stream.sh`
- **Stop Stream:** `bash stop-stream.sh`

**Audio Setup:**
Place your background music file at: `~/mt5-vnc/audio/BackgroundNocopyright.mp3`. 
*(Note: For Container Mode, copy the file into the container: `sudo docker cp ~/mt5-vnc/audio/BackgroundNocopyright.mp3 mt5-workbench:/home/abc/audio/`)*

### 3. Configuration Matrix

| Component | Host Port | Container Port | Path / Variable |
| :--- | :--- | :--- | :--- |
| **noVNC Web UI** | 3000 | 3000 | `/usr/share/novnc` |
| **VNC Server** | 5901 | 5901 | `:1` |
| **MT5 Data** | `~/mt5-data` | `/home/abc/.wine` | `.wine` folder |
| **Stream Key** | N/A | N/A | `.env` $\rightarrow$ `STREAM_KEY` |

---

## 🛠 Troubleshooting

### "Failed to connect to server" (noVNC)
If you see the noVNC page but cannot connect:
1. **X11 Authorization**: Ensure `xhost +` has been executed inside the container. The `start-stream.sh` and `entrypoint.sh` handle this automatically.
2. **Browser Cache**: Clear browser cache or try Incognito mode. Chrome extensions can sometimes interfere with the `ui.js` event listeners.

### MT5 Not Launching
If the VNC desktop is empty:
- Check the logs: `sudo docker exec mt5-workbench tail -f /home/abc/.vnc/*.log`
- Ensure the MT5 binary exists at `/home/abc/.wine/drive_c/Program Files/MetaTrader 5/terminal64.exe`.

---

## 📂 Project Structure

- `setup.sh` $\rightarrow$ The Installation Wizard.
- `entrypoint.sh` $\rightarrow$ The Master Runtime Blueprint (Single source of truth for launch logic).
- `start-stream.sh` $\rightarrow$ YouTube streaming orchestrator.
- `stop-stream.sh` $\rightarrow$ Stream termination utility.
- `docker-compose.yml` $\rightarrow$ Infrastructure as Code for Host mode.
- `Dockerfile` $\rightarrow$ System image definition.
- `mt5-data/` $\rightarrow$ Persistent storage for MT5 profiles and audio.
