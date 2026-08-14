-#!/usr/bin/env bash
set -Eeuo pipefail

cd /home/container

export HOME=/home/container
export CARGO_HOME==/home/container/.cargo
export RUSTUP_HOME=/opt/rustup
export PATH="/opt/cargo/bin:$PATH"
export CARGO_BUILD_JOBS="${CARGO_BUILD_JOBS:-2}"
export RUST_LOG="${RUST_LOG:-info}"

log() {
    printf '[stoat-dev] %s\n' "$*"
}

if [[ ! -d source/.git ]]; then
    log "fonte ausente; execute a reinstalação do servidor"
    exit 1
fi

if [[ ! -d scripts ]]; then
    cp -R /opt/stoat-template/scripts /home/container/scripts
fi

if [[ ! -d supervisor ]]; then
    cp -R /opt/stoat-template/supervisor /home/container/supervisor
fi

mkdir -p \
    .data/mongodb \
    .data/redis \
    .data/rabbitmq \
    .data/minio \
    .data/logs \
    .data/run

if [[ "${PULL_ON_START:-0}" == "1" ]]; then
    log "atualizando ${GIT_BRANCH:-main}"
    git -C source fetch origin "${GIT_BRANCH:-main}"
    git -C source merge --ff-only "origin/${GIT_BRANCH:-main}"
fi

PUBLIC_HOST="${PUBLIC_HOST:-${SERVER_IP:-127.0.0.1}}"
PUBLIC_SCHEME="${PUBLIC_SCHEME:-http}"
PUBLIC_WS_SCHEME="${PUBLIC_WS_SCHEME:-ws}"

cat > source/Revolt.overrides.toml <<EOF
production = false
environment = "dev-pterodactyl"

[database]
mongodb = "mongodb://127.0.0.1:27017/?replicaSet=rs0"
redis = "redis://127.0.0.1:6379/"

[rabbit]
host = "127.0.0.1"
port = 5672
username = "rabbituser"
password = "rabbitpass"

[hosts]
app = "${PUBLIC_SCHEME}://${PUBLIC_HOST}:14701"
api = "${PUBLIC_SCHEME}://${PUBLIC_HOST}:14702"
events = "${PUBLIC_WS_SCHEME}://${PUBLIC_HOST}:14703"
autumn = "${PUBLIC_SCHEME}://${PUBLIC_HOST}:14704"
january = "${PUBLIC_SCHEME}://${PUBLIC_HOST}:14705"

[api.smtp]
host = ""

[files.s3]
endpoint = "http://127.0.0.1:14009"
region = "minio"
access_key_id = "minioautumn"
secret_access_key = "minioautumn"
default_bucket = "revolt-uploads"
EOF

if [[ "${BUILD_ON_START:-1}" == "1" || ! -x source/target/debug/revolt-delta ]]; then
    log "compilando backend; o primeiro build pode demorar"
    (cd source && cargo build)
    log "backend compilado"
fi
if [ -f /home/container/.erlang.cookie ]; then
    chmod 600 /home/container/.erlang.cookie
fi

export RABBITMQ_MNESIA_BASE=/home/container/.data/rabbitmq/mnesia
export RABBITMQ_LOG_BASE=/home/container/.data/rabbitmq/log
export RABBITMQ_PID_FILE=/home/container/.data/run/rabbitmq.pid
export RABBITMQ_DEFAULT_USER=rabbituser
export RABBITMQ_DEFAULT_PASS=rabbitpass
export MINIO_ROOT_USER=minioautumn
export MINIO_ROOT_PASSWORD=minioautumn
export MINIO_REGION=minio
export ENABLE_PUSHD="${ENABLE_PUSHD:-0}"

log "iniciando infraestrutura e serviços Stoat"
exec supervisord -n -c /home/container/supervisor/supervisord.conf


