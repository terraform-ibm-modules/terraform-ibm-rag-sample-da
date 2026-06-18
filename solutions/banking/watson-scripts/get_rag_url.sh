#!/bin/bash

set -euo pipefail

PIPELINE_ID="${1:-}"

if [ -z "$PIPELINE_ID" ]; then
  echo '{"url":"","error":"Missing pipeline id"}'
  exit 0
fi

echo "Checking CD pipeline: $PIPELINE_ID" >&2

# Get logs safely (don’t fail script if command fails)
LOGS=$(ibmcloud dev pipeline-log "$PIPELINE_ID" 2>/dev/null || true)

# Extract Code Engine URL (if present)
APP_URL=$(echo "$LOGS" | grep -Eo 'https://[^ ]*codeengine[^ ]*' | head -1 || true)

if [ -z "$APP_URL" ]; then
  echo '{"url":"","error":"URL not found in pipeline logs"}'
  exit 0
fi

# Terraform external data source requires valid JSON on stdout
echo "{\"url\":\"$APP_URL\"}"
