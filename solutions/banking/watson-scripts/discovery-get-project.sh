#!/usr/bin/env bash

set -e

eval "$(jq -r '@sh "IAM_TOKEN=\(.tokendata) WATSON_DISCOVERY_URL=\(.watson_discovery_url)"')"
token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

PROJECT_ID=$(curl -X GET --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.projects[] | select(.name == "gen-ai-rag-sample-app-project") | .project_id ')

jq -n --arg discovery_project_id "$PROJECT_ID" '{"discovery_project_id": $discovery_project_id}'
