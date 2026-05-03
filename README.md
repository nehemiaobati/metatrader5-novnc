# MT5 Workbench (Docker Blueprint)

A standardized, portable, and self-contained environment for MetaTrader 5 automated trading.

## Project Structure
Every project must follow this structure to ensure portability:

```text
/docker/mt5-workbench/
├── docker-compose.yml       # The immutable source of truth
├── Dockerfile               # Build context
├── .env.template            # Required vars (STREAM_KEY)
├── Makefile                 # Standardized lifecycle commands
├── README.md                # Project-specific documentation
└── volumes/                 # Local persistence
    ├── data/
    │   └── audio/           # Streaming assets
    └── config/
        └── .wine/           # MT5 profile, terminal, and EAs
```

## Core Principles
1. **Absolute Self-Containment**: All data resides in `volumes/`.
2. **Relative Paths**: `docker-compose.yml` uses relative volume mounts exclusively.
3. **Lifecycle**: Managed via `Makefile`.

## 🚀 Quick Start
- `make up`: Start service
- `http://<server-ip>:3000/vnc.html`: Access VNC
- `make stream-start`: Start streaming
- `make stream-stop`: Stop streaming
- `make backup`: Backup data

## 📖 Operation Manual

### VNC Authentication
The VNC server requires a password to prevent unauthorized access.
- **Default Password**: `password`

### Changing the Password
You can change the password on a running system:

```bash
sudo docker exec -it -u abc mt5-workbench vncpasswd
```

⚠️ **CRITICAL**: Password changes are not instant. You **must** restart the container for the new password to load from disk:

```bash
sudo docker restart mt5-workbench
```

### Streaming Setup
1. Create a `.env` file in the project root.
2. Add your key: `STREAM_KEY=your_youtube_stream_key_here`
3. Place your background audio at `./volumes/data/audio/BackgroundNocopyright.mp3`.

### Troubleshooting
- **Empty Desktop**: Check logs via `make logs` or `sudo docker exec mt5-workbench tail -f /home/abc/.vnc/*.log`.
- **Connection Failed**: Ensure port 3000 is open and the container is running.
