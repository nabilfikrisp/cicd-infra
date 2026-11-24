
#!/usr/bin/env bash

set -Eeuo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Reverse dependency order
STACKS=(
    "arcane"
    "tailscale"
)

log() {
    printf '[INFO] %s\n' "$*"
}

error() {
    printf '[ERROR] %s\n' "$*" >&2
    exit 1
}

compose() {
    local stack="$1"
    shift

    docker compose \
        --project-directory "$INFRA_DIR/$stack" \
        --env-file "$INFRA_DIR/$stack/.env" \
        -f "$INFRA_DIR/$stack/compose.yml" \
        "$@"
}

# Check dependencies
command -v docker >/dev/null 2>&1 \
    || error "Docker is not installed."

docker compose version >/dev/null 2>&1 \
    || error "Docker Compose is not installed."

docker info >/dev/null 2>&1 \
    || error "Docker daemon is unavailable."

# Validate configuration before teardown
for stack in "${STACKS[@]}"; do
    [[ -f "$INFRA_DIR/$stack/compose.yml" ]] \
        || error "Missing compose.yml for $stack."

    [[ -f "$INFRA_DIR/$stack/.env" ]] \
        || error "Missing .env for $stack."

    compose "$stack" config --quiet
done

# Gracefully teardown stacks
for stack in "${STACKS[@]}"; do
    log "Stopping $stack..."

    compose "$stack" down --timeout 30

    log "$stack stopped successfully."
done

log "Infrastructure teardown completed."
log "Persistent volumes and configuration preserved."
