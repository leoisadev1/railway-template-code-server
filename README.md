# Deploy and Host code-server on Railway

A personal VS Code workspace in the browser, using code-server 4.146.0 (VS Code 1.146.0) with Node.js 24 LTS, npm, Python 3.13, and a persistent home directory. This is one editor service, not the Coder control plane.

## About Hosting code-server

The Dockerfile pins the code-server image by digest, installs Node.js 24 LTS from nodejs.org with pinned release checksums and runs the editor server on it, and adds Python and build tools from Debian. Startup initializes ownership of the mounted home, then runs the editor and integrated terminal as `coder` (UID 1000). Password authentication is explicitly enabled.

### Deploy and sign in

1. Deploy with the `/home/coder` volume attached.
2. Copy the generated `PASSWORD` from the service's Railway Variables tab.
3. Open your public HTTPS domain and sign in on the code-server login page.
4. Open a folder beneath `/home/coder`. Use Terminal → New Terminal to check `id`, `pwd`, `node --version`, and `python --version`.
5. Save an editor file, reload it, and verify it again after a restart before depending on the workspace for important work.

### Authentication and ports

- `PASSWORD` defaults to Railway's `${{secret()}}` generator. Do not use a shared or dummy password.
- Optional `HASHED_PASSWORD` accepts an upstream-supported Argon2 hash and takes precedence over `PASSWORD`; remove the plaintext variable when switching to a hash. Startup rejects empty credentials even if an old config file contains a password.
- `PORT` defaults to `8080` and is passed explicitly to the editor. Keep an explicitly configured domain target port aligned with it.
- Railway terminates HTTPS and forwards HTTP/WebSocket traffic to the container. There is no bundled SSH daemon.
- Anonymous requests to the editor (`/`, `/vscode`), the port proxies (`/proxy/<port>/`, `/absproxy/<port>/`) and the editor and proxy websockets are redirected to the login page or refused with 401. The session cookie is `HttpOnly`, and code-server strips it from requests it forwards to proxied ports. Proxied pages share the editor's origin, so open only services you trust through the proxy.
- `/healthz` is an unauthenticated process-heartbeat endpoint, with a 60-second startup healthcheck allowance. It does not prove a successful editor save, authenticated session, or terminal connection.

### Persistence and access boundaries

The `/home/coder` volume stores projects, editor settings, Open VSX extensions, git configuration, and code-server configuration. Existing root-owned files are migrated without following symlinks; existing user-owned content is preserved. Keep Python virtual environments and other user-installed dependencies under the mounted home. Add system packages in the Dockerfile rather than relying on ephemeral container changes.

The upstream image includes passwordless sudo: an authenticated terminal user can become root. Running the editor as coder is not a privilege boundary. Use one workspace service for trusted users only. Integrated-terminal access includes workspace files and the application's environment; this is not isolation between untrusted developers. Back up the home volume separately and test recovery before upgrades.

code-server 4.146.0 bundles VS Code 1.146.0, which includes the Workspace Trust, MCP and extension-dialog fixes from VS Code 1.145.3. Open folders you do not trust in Restricted Mode, and install extensions and MCP servers only from publishers you trust: an extension or MCP server runs with the workspace user's full access.

## Common Use Cases

- Browser-based Node.js and Python development.
- Personal git working trees and Open VSX extensions.
- A persistent editor without running a full Coder control plane.

## Dependencies for code-server Hosting

A Railway service, `/home/coder` volume, generated password, and public HTTPS domain.

### Deployment Dependencies

- [Template source](https://github.com/leoisadev1/railway-template-code-server).
- [code-server documentation and source](https://github.com/coder/code-server).
- The Dockerfile's pinned image and installed development tools.

## Why Deploy code-server on Railway?

Railway hosts the editor container, HTTPS/WebSocket routing, and home volume. You control workspace access, tool updates, backups, and the resources allocated to builds and development processes.

## Verification limits

Release v1.1.3 builds the same image as v1.1.2. Railway stops reading `railway.toml` on 2026-12-01. The template's stored configuration already held the `/healthz` health check and restart on failure up to 10 times, and Railway builds the `Dockerfile` it finds at the repository root, but it held no health-check timeout. v1.1.3 proposes adding the 60-second timeout to the stored configuration; until a readback of the template shows it, deployments after the cutoff use Railway's 300-second default. `railway.toml` keeps the same values. v1.1.3 was verified locally on amd64 with `scripts/smoke.sh`, which now requires `/healthz` to answer within 60 seconds after every start. On Railway, the v1.1.2 checks below apply to the same image. No Railway deployment has yet run with the stored timeout or without `railway.toml`, and the v1.1.2 records show where Railway took the timeout from, not that a 60-second deadline was in effect.

Release v1.1.2 (code-server 4.146.0 with VS Code 1.146.0, and the editor server on Node.js 24.22.3 instead of the bundled 24.22.1) was verified locally on amd64 with `scripts/smoke.sh`, which also loads every bundled native module under that Node.js, spawns a terminal process, and upgrades a volume first used by v1.1.1. It was then deployed to Railway amd64 on 2026-11-22 from the live listing's stored configuration, building `release-v1`. The remote checks covered the pinned code-server image, the health check, login redirects for the editor and both port proxies, a refused anonymous websocket, wrong-password rejection, the `HttpOnly` session cookie, authenticated editor and websocket access, the served version 4.146.0, logs with no error lines besides the deliberate wrong-password attempt and no password, and the same checks after a redeploy that reused the stored code-server config. Editor saves and terminal commands were not repeated on Railway; the local smoke covers them.

Release v1.1.1 ships the same Dockerfile, entrypoint and Railway configuration as v1.1.0, so the checks below still apply. It adds guidance on the VS Code advisories that code-server has not shipped yet, and local tests for Argon2 login and for refusing to start without a credential.

Release v1.1.0 (code-server 4.145.2, Node.js 24.22.3) was verified locally on amd64 with `scripts/smoke.sh`, then deployed to Railway amd64 on 2026-11-18 from the live listing's configuration. The remote checks covered the health check, login redirects for the editor and both port proxies, a refused anonymous websocket, wrong-password rejection, the `HttpOnly` session cookie, authenticated editor and websocket access, the served code-server version, and login and the stored code-server config surviving a redeploy. Editor saves and terminal commands were not repeated on Railway for v1.1.0; the local smoke covers them.

Earlier Railway checks against v1.0.0 (code-server 4.135.0) exercised generated-password browser login, editor saves, terminal commands, restart/redeploy file persistence, and root-owned-file migration on Railway amd64. Port 9123 was exercised in cloud; the 8080 fallback has local regression coverage. Argon2 `HASHED_PASSWORD` login has local regression coverage since v1.1.1 but was not tested on Railway; arm64 runtime and extension installation/persistence were not tested. Mobile checks used a 390×844 server-side Chromium viewport, not a physical phone: login and a resized terminal worked, but the default desktop layout is cramped and a full mobile editor-save workflow was not tested.
