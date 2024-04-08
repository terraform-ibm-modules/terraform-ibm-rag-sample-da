#!/usr/bin/env bash

set -e

IAM_TOKEN="$1"
WATSON_ASSISTANT_URL=$2

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

curl -X POST --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "{\"name\":\"gen-ai-rag-sample-app-assistant\",\"language\":\"en\",\"description\":\"Generative AI sample app assistant\"}"
