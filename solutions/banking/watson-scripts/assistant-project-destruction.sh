#!/usr/bin/env bash

set -e

project_name="gen-ai-rag-sample-app-assistant"

eval "$(jq -r '@sh "IAM_TOKEN=\(.tokendata) WATSON_ASSISTANT_URL=\(.watson_assistant_url)"')"
token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

export token

ASSISTANT_ID=$(curl --retry 3 -fLsS -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.assistants[] | select(.name == "'$project_name'") | .assistant_id ')


curl -X DELETE --location "$WATSON_ASSISTANT_URL/v2/assistants/$ASSISTANT_ID?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json"
