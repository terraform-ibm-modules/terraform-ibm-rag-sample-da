#!/usr/bin/env bash

set -euo pipefail

WATSON_DISCOVERY_URL=$1
DISCOVERY_PROJECT_NAME="gen-ai-rag-sample-app-project"
DISCOVERY_COLLECTION_NAME="gen-ai-rag-sample-app-data"

# Expects the environment variable $IBMCLOUD_API_KEY to be set
if [[ -z "${IAM_TOKEN}" ]]; then
    echo "API key must be set with IAM_TOKEN environment variable" >&2
    exit 1
fi

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

PROJECT_ID=$(curl -X GET --retry 3 -flsS --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r --arg DISCOVERY_PROJECT_NAME "$DISCOVERY_PROJECT_NAME" '.projects[] | select(.name==$DISCOVERY_PROJECT_NAME) | .project_id ')

EXISTING_COLLECTION_ID=$(curl -X GET --retry 3 -flsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r --arg DISCOVERY_COLLECTION_NAME "$DISCOVERY_COLLECTION_NAME" '.collections[] | select(.name==$DISCOVERY_COLLECTION_NAME) | .collection_id ')

if [[ -z $EXISTING_COLLECTION_ID ]]; then
    curl -X POST -flsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
        --header "Authorization: Bearer $token" \
        --header "Content-Type: application/json" \
        --data "{ \"name\": \"$DISCOVERY_COLLECTION_NAME\", \"description\": \"Sample data\" }"
    echo "Collection '$DISCOVERY_COLLECTION_NAME' created"
else
    echo "Collection '$DISCOVERY_COLLECTION_NAME' already exists, skipping..."
    exit 0
fi
