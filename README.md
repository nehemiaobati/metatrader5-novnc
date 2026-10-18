# MT5 Workbench (Docker Blueprint)

A standardized, portable, and self-contained environment for MetaTrader 5 automated trading.

## Project Structure

```text
mt5-workbench/
├── docker-compose.yml       # The immutable source of truth
├── Dockerfile               # Build context
├── .env.template            # Required environment variables (STREAM_KEY)
├── Makefile                 # Standardized lifecycle commands
├── README.md                # Operational documentation
├── start-stream.sh          # Unified streaming engine (RTMP / HLS)
├── start-stream-hls.sh      # HLS stream wrapper
├── stop-stream.sh           # Stream cleanup script
└── volumes/                 # Local persistence
    ├── data/
    │   └── audio/           # Streaming assets
    └── config/
        └── .wine/           # MT5 profile, terminal, and EAs
```

## Core Principles

1. **Absolute Self-Containment**: All runtime data resides strictly within `volumes/`.
2. **Relative Paths**: Configuration uses relative mounts and dynamic script execution to maintain environment portability.
3. **Lifecycle Management**: Entire container and stream lifecycle is managed deterministically via `Makefile`.

---

## 🚀 Quick Start

- `make up`: Start MT5 workbench container in background
- `http://<server-ip>:3000/vnc.html`: Access browser VNC (Default password: `password`)
- `make stream-start`: Start background YouTube RTMP streaming
- `make stream-start-hls`: Start background YouTube HLS streaming
- `make stream-stop`: Stop active streaming processes
- `make backup`: Create timestamped backup archive of `./volumes`

---

## 📖 Operation Manual

### VNC Authentication
The VNC server requires password authentication to secure the remote desktop.
- **Default Password**: `password`

#### Updating the Password
You can update the password inside the running container:

```bash
sudo docker exec -it -u abc mt5-workbench vncpasswd
```

Restart the container to load the new credentials:

```bash
make restart
```

> **Note**: Your updated password is saved to disk and will persist across container restarts.

---

### Streaming Setup

1. Copy the environment template:
   ```bash
   cp .env.template .env
   ```

2. Add your YouTube Stream Key to `.env`:
   ```bash
   STREAM_KEY=xxxx-xxxx-xxxx-xxxx-xxxx
   ```

3. Place your background audio track at:
   ```text
   ./volumes/data/audio/BackgroundNocopyright.mp3
   ```

---

### Stream Management

#### Starting the Stream
Streams are launched detached via `nohup` so they persist after disconnecting from your terminal session:

- **RTMP Stream** (Default low latency):
  ```bash
  make stream-start
  ```
- **HLS Stream** (Enhanced stability / HTTP ingestion):
  ```bash
  make stream-start-hls
  ```

#### Stopping the Stream
To gracefully terminate the streaming loops and FFmpeg processes:

```bash
make stream-stop
```

#### Monitoring Stream Logs
Follow the active stream output in real-time:

```bash
tail -f /tmp/stream_wrapper.log
```

---

### 🔧 Troubleshooting

- **Empty Desktop / Display Issues**: Check TigerVNC server logs:
  ```bash
  sudo docker exec mt5-workbench tail -f /home/abc/.vnc/*.log
  ```
- **Stream Stalling / Restarting**: Inspect the FFmpeg output log:
  ```bash
  sudo docker exec mt5-workbench tail -f /tmp/ffmpeg.log
  ```
- **Container Connection Issues**: Ensure ports `3000` (noVNC web) and `5901` (VNC core) are accessible and check container status:
  ```bash
  make logs
  ```
