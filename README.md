# happy-free-claude-code

Run [Happy](https://happy.engineering) sessions through [Free Claude Code](https://github.com/Alishahryar1/free-claude-code), routing API calls through a local proxy.

## Prerequisites

1. Install Happy from npm:
   ```bash
   npm install -g happy
   ```

2. Install and start **fcc-server** (see [free-claude-code](https://github.com/Alishahryar1/free-claude-code)). It must be listening on port 8082 (or your configured port in `~/.fcc/.env`).

## Usage

```bash
# Start fcc-server in one terminal
fcc-server

# Run Happy via the wrapper
./happy-fcc
```

Pass any Happy/Claude flags through:
```bash
./happy-fcc --resume
./happy-fcc --yolo
```

## What the script does

Replicates Free Claude Code's `_claude_child_env()` before launching Happy:

1. Strips all `ANTHROPIC_*` environment variables (real API keys never reach Claude)
2. Reads proxy port and auth token from `~/.fcc/.env` (defaults to port 8082)
3. Passes `ANTHROPIC_BASE_URL`, `ANTHROPIC_AUTH_TOKEN`, and gateway settings to Happy via `--claude-env`

Works for both **local** (PTY) and **remote** (SDK) modes.
