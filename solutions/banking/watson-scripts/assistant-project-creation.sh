#!/usr/bin/env bash

set -e

IAM_TOKEN="$1"
WATSON_ASSISTANT_URL=$2

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

ASSISTANT_ID=$(curl -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.assistants[] | select(.name == "gen-ai-rag-sample-app-assistant") | .assistant_id ')

if [ -z "$ASSISTANT_ID" ]; then
  # if not ASSISTANT_ID is found then create a new assistant project
  curl -X POST --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json" \
      --data "{\"name\":\"gen-ai-rag-sample-app-assistant\",\"language\":\"en\",\"description\":\"Generative AI sample app assistant\"}"
else
  # If ASSISTANT_ID exists in a project then do not create another project.
  echo "gen-ai-rag-sample-app-assistant project aleady exists."
  exist 0
fi
