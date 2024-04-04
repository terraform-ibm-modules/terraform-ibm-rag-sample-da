#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "IAM_TOKEN=\(.tokendata) WATSON_ASSISTANT_URL=\(.watson_assistant_url)"')"
token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

ASSISTANT_ID=$(curl -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.assistants[] | select(.name == "gen-ai-rag-sample-app-assistant") | .assistant_id ')

ENVIRONMENT=$(curl -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants/$ASSISTANT_ID/environments?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.environments[] | select(.name == "draft") ')

INTEGRATION_ID=$(echo "$ENVIRONMENT" | jq -r '.integration_references[] | select(.type == "web_chat") | .integration_id ')

jq -n --arg assistant_integration_id "$INTEGRATION_ID" '{"assistant_integration_id": $assistant_integration_id}'
