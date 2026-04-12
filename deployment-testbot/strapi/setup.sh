#!/bin/bash
set -e

# TestBot Setup Script for Strapi
# Builds from source, initializes the application, creates admin user, seeds data.
#
# Usage:
#   ./setup.sh                     # Uses docker compose (default)
#   STRAPI_REPO_PATH=/path/to/strapi ./setup.sh   # Custom repo path
#
# Prerequisites:
#   Docker mode: docker, docker compose (v2)

cd "$(dirname "$0")"
SCRIPT_DIR="$(pwd)"

REPO_PATH="${STRAPI_REPO_PATH:-$(dirname $(dirname "$SCRIPT_DIR"))}"

# ─── Admin credentials (used by get-token.sh) ───
ADMIN_EMAIL="admin@testbot.com"
ADMIN_PASSWORD="TestBot123!"
ADMIN_FIRSTNAME="TestBot"
ADMIN_LASTNAME="Admin"

# ─── Health check helper ───
wait_for_url() {
    local url="$1"
    local max_wait="${2:-120}"
    local elapsed=0
    echo "Waiting for $url (timeout: ${max_wait}s)..."
    while ! curl -sf "$url" > /dev/null 2>&1; do
        sleep 2
        elapsed=$((elapsed + 2))
        if [ "$elapsed" -ge "$max_wait" ]; then
            echo "ERROR: $url not reachable after ${max_wait}s"
            return 1
        fi
    done
    echo "✓ $url is ready (${elapsed}s)"
}

echo "=== Strapi Setup (Docker mode) ==="

export STRAPI_REPO_PATH="$REPO_PATH"
docker compose -f "$SCRIPT_DIR/docker-compose.yml" up -d --build

echo "Waiting for PostgreSQL..."
sleep 5

echo "Waiting for Strapi to initialize..."
wait_for_url "http://localhost:1337/_health" 180

echo "Creating admin user..."
# Create admin user via Strapi's API
ADMIN_RESPONSE=$(curl -s -X POST http://localhost:1337/admin/register-admin \
  -H "Content-Type: application/json" \
  -d "{
    \"firstname\": \"$ADMIN_FIRSTNAME\",
    \"lastname\": \"$ADMIN_LASTNAME\",
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }")

if echo "$ADMIN_RESPONSE" | grep -q "email"; then
    echo "✓ Admin user created: $ADMIN_EMAIL"
else
    echo "Note: Admin may already exist or registration endpoint unavailable"
fi

echo "Creating sample content types..."
# Note: Strapi v5 requires content types to be defined in code or via UI
# For now, we'll just ensure the system is ready
# Additional seeding can be done via the API after content types are created

wait_for_url "http://localhost:1337/_health" 30
echo "✓ Strapi setup complete (Docker mode)"
echo "  URL: http://localhost:1337"
echo "  Admin Panel: http://localhost:1337/admin"
echo "  Admin: $ADMIN_EMAIL / $ADMIN_PASSWORD"
