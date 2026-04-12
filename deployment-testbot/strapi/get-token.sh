#!/bin/bash
# TestBot Auth Token Script for Strapi
#
# Strapi uses JWT authentication for admin users.
# This script logs in via the admin login endpoint and extracts the JWT token.
#
# Prerequisites: Strapi must be running and admin user must exist.

ADMIN_EMAIL="${STRAPI_ADMIN_EMAIL:-admin@testbot.com}"
ADMIN_PASSWORD="${STRAPI_ADMIN_PASSWORD:-TestBot123!}"
API_BASE="${STRAPI_API_BASE:-http://localhost:1337}"

# Login and get JWT token
RESPONSE=$(curl -s -X POST "$API_BASE/admin/login" \
  -H "Content-Type: application/json" \
  -d "{
    \"email\": \"$ADMIN_EMAIL\",
    \"password\": \"$ADMIN_PASSWORD\"
  }")

# Extract token from response
TOKEN=$(echo "$RESPONSE" | grep -o '"token":"[^"]*' | grep -o '[^"]*$')

if [ -z "$TOKEN" ] || [ "$TOKEN" = "null" ]; then
    echo "ERROR: Failed to get JWT token from Strapi" >&2
    echo "Response: $RESPONSE" >&2
    exit 1
fi

echo "$TOKEN"
