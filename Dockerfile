# codercom/code-server 4.135.0 (Code 1.135.0, Docker Hub 2026-08-27)
# index digest sha256:ccd326184d71efc5ebb94155eda7bb30153902342a35dbc8525450d81aa55012
FROM codercom/code-server:4.135.0

USER root
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    python3-full \
    nodejs \
    npm \
    build-essential \
  && ln -sf /usr/bin/python3 /usr/local/bin/python \
  && rm -rf /var/lib/apt/lists/*

COPY entrypoint.sh /usr/local/bin/railway-entrypoint.sh
RUN chmod 755 /usr/local/bin/railway-entrypoint.sh

USER 1000
WORKDIR /home/coder
EXPOSE 8080
ENTRYPOINT ["/usr/local/bin/railway-entrypoint.sh"]
