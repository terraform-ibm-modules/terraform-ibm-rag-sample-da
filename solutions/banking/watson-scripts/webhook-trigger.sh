#!/usr/bin/env bash

set -euo pipefail

if [ -z "$WEBHOOK_URL" ]; then
  echo "WEBHOOK_URL not set" >&2
  exit 1
fi

if [ -z "$WEBHOOK_SECRET" ]; then
  echo "WEBHOOK_SECRET not set" >&2
  exit 1
fi

echo "[INFO] Attempting webhook trigger."

curl -fsS -X POST \
  --connect-timeout 10 \
  --max-time 30 \
  --retry 3 \
  --retry-delay 10 \
  --retry-connrefused \
  -H "Content-Type: application/json" \
  --data "{\"webhook-token\":\"$WEBHOOK_SECRET\"}" \
  "$WEBHOOK_URL"

echo "[INFO] Webhook trigger succeeded."
