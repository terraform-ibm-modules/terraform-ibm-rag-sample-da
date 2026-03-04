#!/usr/bin/env bash

set -euo pipefail
set +x

if [ -z "$WEBHOOK_URL" ]; then
  echo "WEBHOOK_URL not set" >&2
  exit 1
fi

if [ -z "$WEBHOOK_SECRET" ]; then
  echo "WEBHOOK_SECRET not set" >&2
  exit 1
fi

MAX_RETRIES=3
RETRY_DELAY=10

for ((i=1; i<=MAX_RETRIES; i++)); do

 echo "[INFO] Attempting webhook trigger: (attempt $i/$MAX_RETRIES)."

  if curl -fsS -X POST \
    -H "Content-Type: application/json" \
    --data "{\"webhook-token\":\"$WEBHOOK_SECRET\"}" \
    "$WEBHOOK_URL"; then

    echo "[INFO] Webhook trigger succeeded."
    exit 0
  fi

  echo "[WARN] Webhook trigger call failed."

  if [ "$i" -lt "$MAX_RETRIES" ]; then
    echo "[INFO] Retrying in $RETRY_DELAY seconds..."
    sleep "$RETRY_DELAY"
  fi
done

echo "[ERROR] Failed to trigger webhook after $MAX_RETRIES attempts."
exit 1
