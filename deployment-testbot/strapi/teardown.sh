#!/bin/bash
# TestBot Teardown Script for Strapi
# Stops containers and cleans up resources

cd "$(dirname "$0")"

echo "=== Strapi Teardown ==="

echo "Stopping containers..."
docker compose down -v

echo "✓ Strapi teardown complete"
