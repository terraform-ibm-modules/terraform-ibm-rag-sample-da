#!/usr/bin/env bash

set -e

IAM_TOKEN="$1"
WATSON_DISCOVERY_URL=$2

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

curl -X POST --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "{ \"name\": \"gen-ai-rag-sample-app-project\",   \"type\": \"document_retrieval\" }"
