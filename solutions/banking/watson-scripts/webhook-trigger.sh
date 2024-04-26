#!/usr/bin/env bash

set -e

WEBHOOK_URL="$1"
WEBHOOK_SECRET="$2"

curl -X POST -fLsS --header "Content-Type: application/json" --data "{\"webhook-token\":\"$WEBHOOK_SECRET\"}" "$WEBHOOK_URL"
