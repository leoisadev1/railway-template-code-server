# Deploy and Host code-server on Railway

A personal VS Code workspace in the browser, using code-server 4.135.0 with Node.js, npm, Python, and a persistent home directory. This is one editor service, not the Coder control plane.

## About Hosting code-server

The Dockerfile pins the code-server image by digest and adds development tools. Startup initializes ownership of the mounted home, then runs the editor and integrated terminal as `coder` (UID 1000). Password authentication is explicitly enabled.

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
- `/healthz` is an unauthenticated process-heartbeat endpoint, with a 60-second startup healthcheck allowance. It does not prove a successful editor save, authenticated session, or terminal connection.

### Persistence and access boundaries

The `/home/coder` volume stores projects, editor settings, Open VSX extensions, git configuration, and code-server configuration. Existing root-owned files are migrated without following symlinks; existing user-owned content is preserved. Keep Python virtual environments and other user-installed dependencies under the mounted home. Add system packages in the Dockerfile rather than relying on ephemeral container changes.

The upstream image includes passwordless sudo: an authenticated terminal user can become root. Running the editor as coder is not a privilege boundary. Use one workspace service for trusted users only. Integrated-terminal access includes workspace files and the application's environment; this is not isolation between untrusted developers. Back up the home volume separately and test recovery before upgrades.

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

Generated-password browser login, editor saves, terminal commands, restart/redeploy file persistence, and root-owned-file migration were exercised on Railway amd64. Port 9123 was exercised in cloud; the 8080 fallback has local regression coverage. Argon2-only browser login, arm64 runtime, and extension installation/persistence were not tested. Mobile checks used a 390×844 server-side Chromium viewport, not a physical phone: login and a resized terminal worked, but the default desktop layout is cramped and a full mobile editor-save workflow was not tested.
