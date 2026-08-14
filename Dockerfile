FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    HOME=/home/container \
    USER=container \
    CARGO_HOME=/opt/cargo \
    RUSTUP_HOME=/opt/rustup \
    PATH=/opt/cargo/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN set -eux; \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        curl \
        gnupg \
        git \
        build-essential \
        pkg-config \
        clang \
        cmake \
        libssl-dev \
        libvips-dev \
        ffmpeg \
        rabbitmq-server \
        supervisor \
        tini \
        netcat-openbsd \
        jq \
        xz-utils \
        unzip; \
    \
    curl -fsSL https://packages.redis.io/gpg \
        | gpg --dearmor --yes \
          -o /usr/share/keyrings/redis-archive-keyring.gpg; \
    chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg; \
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb jammy main" \
        > /etc/apt/sources.list.d/redis.list; \
    printf '%s\n' \
        'Package: redis redis-server redis-sentinel redis-tools' \
        'Pin: version 6:7.4.*' \
        'Pin-Priority: 1001' \
        > /etc/apt/preferences.d/redis; \
    \
    curl -fsSL https://pgp.mongodb.com/server-8.0.asc \
        | gpg --dearmor --yes \
          -o /usr/share/keyrings/mongodb-server-8.0.gpg; \
    chmod 644 /usr/share/keyrings/mongodb-server-8.0.gpg; \
    echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/8.0 multiverse" \
        > /etc/apt/sources.list.d/mongodb-org-8.0.list; \
    \
    apt-get update; \
    apt-get install -y --no-install-recommends \
        redis-server \
        redis-tools \
        mongodb-org-server \
        mongodb-mongosh; \
    \
    redis-server --version; \
    \
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
        | sh -s -- \
          -y \
          --profile minimal \
          --default-toolchain 1.92.0; \
    rustup component add rustfmt clippy; \
    \
    architecture="$(dpkg --print-architecture)"; \
    case "$architecture" in \
        amd64) minio_arch=amd64 ;; \
        arm64) minio_arch=arm64 ;; \
        *) echo "Arquitetura não suportada: $architecture"; exit 1 ;; \
    esac; \
    \
    curl -fsSL \
        "https://dl.min.io/server/minio/release/linux-${minio_arch}/minio" \
        -o /usr/local/bin/minio; \
    curl -fsSL \
        "https://dl.min.io/client/mc/release/linux-${minio_arch}/mc" \
        -o /usr/local/bin/mc; \
    chmod +x /usr/local/bin/minio /usr/local/bin/mc; \
    \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p \
        /home/container \
        /opt/stoat-template/scripts \
        /opt/stoat-template/supervisor; \
    chmod -R a+rX /opt/cargo /opt/rustup

COPY scripts/ /opt/stoat-template/scripts/
COPY supervisor/ /opt/stoat-template/supervisor/

RUN chmod +x /opt/stoat-template/scripts/*.sh

WORKDIR /home/container

STOPSIGNAL SIGTERM

ENTRYPOINT ["/usr/bin/tini", "-g", "--"]

CMD ["bash", "/home/container/scripts/start.sh"]