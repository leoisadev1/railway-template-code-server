# code-server 4.145.2 (Code 1.145.2), pinned to the verified multi-architecture image index.
FROM docker.io/codercom/code-server:4.145.2@sha256:09565f9e07f5624554e295e8bab0e2fec4a7c533eb3cff459ed6596a4d3d7c1c

ARG TARGETARCH
USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    build-essential \
    util-linux \
    xz-utils \
  && apt-get upgrade -y --no-install-recommends \
  && ln -sf /usr/bin/python3 /usr/local/bin/python \
  && rm -rf /var/lib/apt/lists/*

# Node.js 24 LTS from nodejs.org. Debian trixie only ships Node.js 20, which is past
# upstream end of life. Checksums come from the release's signed SHASUMS256.txt.
RUN set -eu; \
  node_version=24.22.3; \
  case "${TARGETARCH:-$(dpkg --print-architecture)}" in \
    amd64) node_arch=x64; node_sha256=4f2b175a6d53a5c617a80dba2676238a0688cef28c6da4eba35c7d844e66fcfb ;; \
    arm64) node_arch=arm64; node_sha256=6e51a2ada00f0011cc266f65d98922b403d7ad88f809ca2aa615a5fe1ce6e86c ;; \
    *) echo "Unsupported architecture for Node.js: ${TARGETARCH:-unknown}" >&2; exit 1 ;; \
  esac; \
  curl -fsSL -o /tmp/node.tar.xz "https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-${node_arch}.tar.xz"; \
  echo "${node_sha256}  /tmp/node.tar.xz" | sha256sum -c -; \
  tar -xJf /tmp/node.tar.xz -C /usr/local --strip-components=1 --no-same-owner \
    --exclude='*/CHANGELOG.md' --exclude='*/LICENSE' --exclude='*/README.md'; \
  rm -f /tmp/node.tar.xz; \
  test "$(node --version)" = "v${node_version}"; \
  npm --version >/dev/null

COPY entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

# The entrypoint initializes the mounted home, then drops to coder before startup.
WORKDIR /home/coder
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
