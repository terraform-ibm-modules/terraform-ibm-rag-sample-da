#!/usr/bin/env bash

set -e

IAM_TOKEN="$1"
WATSON_DISCOVERY_URL="$2"
ARTIFACT_DIRECTORY="$3"

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

PROJECT_ID=$(curl -X GET --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.projects[] | select(.name == "gen-ai-rag-sample-app-project") | .project_id ')

COLLECTION_ID=$(curl -X GET --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.collections[] | select(.name == "gen-ai-rag-sample-app-data") | .collection_id ')

for i in {1..7};
do
    curl -X POST --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections/$COLLECTION_ID/documents?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --form "file=@$ARTIFACT_DIRECTORY/FAQ-$i.pdf" \
    --form metadata="{\"field_name\": \"text\"}"
done
