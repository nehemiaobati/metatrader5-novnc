# MT5 Workbench (Docker Blueprint)

A standardized, portable, and self-contained environment for MetaTrader 5 automated trading.

## Project Structure
```text
/docker/mt5-workbench/
├── docker-compose.yml       # The immutable source of truth
├── Dockerfile               # Build context
├── .env.template            # Required vars (STREAM_KEY)
├── Makefile                 # Lifecycle commands
├── README.md                # This documentation
└── volumes/                 # Local persistence
    ├── data/
    │   └── audio/           # Streaming assets
    └── config/
        └── .wine/           # MT5 profile, terminal, and EAs
```

## Core Principles
1. **Absolute Self-Containment**: All data (MT5 profiles, terminal, EAs, audio assets) resides in `volumes/`.
2. **Relative Paths**: `docker-compose.yml` uses relative volume mounts exclusively.

## Quick Start
```bash
make up
make stream-start
make backup
```
- **Access VNC**: `http://<server-ip>:3000/vnc.html`
