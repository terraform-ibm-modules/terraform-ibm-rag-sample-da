#!/usr/bin/env bash

set -e

IAM_TOKEN="$1"
WATSON_DISCOVERY_URL=$2

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

PROJECT_ID=$(curl -X GET --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.projects[] | select(.name == "gen-ai-rag-sample-app-project") | .project_id ')

curl -X POST --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "{ \"name\": \"gen-ai-rag-sample-app-data\", \"description\": \"Sample data\" }"
