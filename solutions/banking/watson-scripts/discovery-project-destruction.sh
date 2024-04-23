#!/usr/bin/env bash

set -e


IAM_TOKEN="$1"
WATSON_DISCOVERY_URL=$2

project_name="gen-ai-rag-sample-app-assistant"

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

export token

PROJECT_ID=$(curl --retry 3 -fLsS -X GET --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.projects[] | select(.name == "'$project_name'") | .project_id ')

#curl --retry 3 -fLsS -X DELETE --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID?version=2023-03-31" \
#    --header "Authorization: Bearer $token" \
#    --header "Content-Type: application/json"


curl -X DELETE -u "apikey:$token" "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID?version=2023-03-31"
