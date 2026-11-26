
#!/usr/bin/env bash

set -Eeuo pipefail

INFRA_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

STACKS=(
    "tailscale"
    "arcane"
    "cloudflared"
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

# Validate all stacks before deployment
for stack in "${STACKS[@]}"; do
    log "Validating $stack..."

    [[ -f "$INFRA_DIR/$stack/compose.yml" ]] \
        || error "Missing compose.yml for $stack."

    [[ -f "$INFRA_DIR/$stack/.env" ]] \
        || error "Missing .env for $stack. Copy .env.example first."

    compose "$stack" config --quiet
done

# Track the Tailscale container identity
previous_id="$(docker inspect \
    --format '{{.Id}}' tailscale 2>/dev/null || true)"

# Deploy Tailscale first
log "Deploying Tailscale..."
compose tailscale up -d

current_id="$(docker inspect \
    --format '{{.Id}}' tailscale)"

# Deploy Arcane
log "Deploying Arcane..."

if [[ "$previous_id" != "$current_id" ]]; then
    log "Tailscale container changed. Recreating Arcane..."
    compose arcane up -d --force-recreate
else
    compose arcane up -d
fi

# Deploy Cloudflared after the private infrastructure
log "Deploying Cloudflared..."
compose cloudflared up -d

log "Infrastructure deployment completed."

for stack in "${STACKS[@]}"; do
    compose "$stack" ps
done
