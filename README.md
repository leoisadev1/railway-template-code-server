# code-server

Pinned VS Code in the browser ([code-server](https://github.com/coder/code-server) `4.135.0`) with a persistent home volume, a generated login password, Node.js + Python, and an HTTP healthcheck.

This is a **single service**. It is not the full Coder control plane.

## One-click deploy

1. Deploy this template on Railway.
2. Open the public HTTPS domain.
3. Sign in with the generated `PASSWORD` variable (Variables tab on the `code-server` service).

The login page is the stock code-server password form. After login you get VS Code in the browser, with `/home/coder` as the workspace.

## Variables

| Variable | Required | Default | Purpose |
| --- | --- | --- | --- |
| `PASSWORD` | generated | `${{secret()}}` | Login password. Railway generates a unique value per deploy. |
| `PORT` | injected | Railway sets this | Listen port. code-server honors `$PORT` over the image default of 8080. |

Optional: set `HASHED_PASSWORD` (argon2) instead of `PASSWORD` if you want a hashed secret. `HASHED_PASSWORD` takes precedence.

Do not set `PASSWORD` to a dummy value in the template. Leave it as the generated secret.

## Volume

| Mount | Why |
| --- | --- |
| `/home/coder` | Persistent home. Settings, Open VSX extensions, `~/.config/code-server`, git config, and project files survive restarts. |

UID 1000 (`coder`) owns the home directory. The entrypoint `chown`s the volume on first boot if Railway mounts it unwritable.

## Ports and healthcheck

- **HTTP** on `$PORT` (image also `EXPOSE 8080`). Railway assigns a public domain to this service.
- Healthcheck: `GET /healthz` (unauthenticated). Returns `{"status":"alive",...}`.
- Restart policy: on failure.

## Login

1. Copy `PASSWORD` from the service variables.
2. Open the Railway-generated HTTPS URL.
3. Paste the password on the code-server login page.

There is no unauthenticated shell and no SSH. Password auth is required.

## Node and Python

The image is `codercom/code-server:4.135.0` plus Debian packages:

- `python3` / `pip` / `venv` (`python` → `python3`)
- `nodejs` and `npm`
- `build-essential` for native addons

Use the integrated terminal: `node -v`, `python --version`, `npm`, `pip`.

## Why this listing vs rotting marketplace clones

Faraz's 2022 `coder/deploy-code-server` still ships **code-server 4.9.0**, with **no volume** and **no healthcheck**. This template:

- Pins a current 4.x tag (`4.135.0`, Code 1.135.0) instead of `:latest` or 4.9.0
- Mounts `/home/coder` so settings and extensions persist
- Generates `PASSWORD` instead of a shared default
- HTTP healthchecks `/healthz` so Railway only routes to a live editor
- Installs Node + Python in the image
- Stays one service (code-server), not Coder's team control plane
