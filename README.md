# Deploy and Host code-server on Railway

Pinned VS Code in the browser ([code-server](https://github.com/coder/code-server) `4.135.0`) with a persistent home volume, a generated login password, Node.js + Python, and an HTTP healthcheck.

This is a **single service**. It is not the full Coder control plane.

## About Hosting code-server

This template builds a thin Dockerfile `FROM codercom/code-server:4.135.0` (Code 1.135.0). Railway gives it a public HTTPS domain. A volume is mounted at `/home/coder` so settings, Open VSX extensions, git config, and project files survive restarts.

The image also installs Node.js, npm, Python 3, pip, venv, and build-essential. code-server listens on `$PORT`, requires password auth, and exposes unauthenticated `GET /healthz`.

## Why Deploy code-server on Railway

Faraz's 2022 `coder/deploy-code-server` marketplace listing still ships **code-server 4.9.0**, with **no volume** and **no healthcheck**. Official Coder is a heavier control plane.

This listing is healthier:

- Pins a current 4.x tag (`4.135.0`) instead of `:latest` or 4.9.0
- Mounts `/home/coder` so settings and extensions persist
- Generates `PASSWORD` (`${{secret()}}`) instead of a shared default
- HTTP healthchecks `/healthz` so Railway only routes to a live editor
- Installs Node + Python in the image
- Stays one service (code-server), not Coder's team control plane

## Common Use Cases

- Browser IDE on a persistent Railway volume
- Remote Node.js / Python development without SSH
- Always-on personal VS Code with Open VSX extensions
- Teaching or demo environments that survive redeploys
- Replacement for rotting 4.9.0 code-server clones

## Dependencies for code-server Hosting

- Public GitHub source: [leoisadev1/railway-template-code-server](https://github.com/leoisadev1/railway-template-code-server)
- Docker image base: `codercom/code-server:4.135.0`
- Railway volume at `/home/coder`
- Generated `PASSWORD` secret
- Public HTTP domain

### Deployment Dependencies

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `PASSWORD` | generated | `${{secret()}}` | Login password. Railway generates a unique value per deploy. |
| `PORT` | injected | Railway sets this | Listen port. code-server honors `$PORT` over the image default of 8080. |

Optional: set `HASHED_PASSWORD` (argon2) instead of `PASSWORD` if you want a hashed secret. `HASHED_PASSWORD` takes precedence.

Do not set `PASSWORD` to a dummy value in the template. Leave it as the generated secret.

| Mount | Why |
| --- | --- |
| `/home/coder` | Persistent home. Settings, Open VSX extensions, `~/.config/code-server`, git config, and project files survive restarts. |

UID 1000 (`coder`) owns the home directory. The entrypoint `chown`s the volume on first boot if Railway mounts it unwritable.

- **HTTP** on `$PORT` (image also `EXPOSE 8080`). Railway assigns a public domain to this service.
- Healthcheck: `GET /healthz` (unauthenticated). Returns `{"status":"alive",...}`.
- Restart policy: on failure.

## After Deploy

1. Copy `PASSWORD` from the `code-server` service Variables tab.
2. Open the Railway-generated HTTPS URL.
3. Sign in on the code-server login page (`Welcome to code-server`).

There is no unauthenticated shell and no SSH. Password auth is required.

Use the integrated terminal after login: `node -v`, `python --version`, `npm`, `pip`.
