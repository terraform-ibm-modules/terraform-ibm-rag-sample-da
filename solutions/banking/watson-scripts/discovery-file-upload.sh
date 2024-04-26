#!/usr/bin/env bash

set -e

WATSON_DISCOVERY_URL="$1"
ARTIFACT_DIRECTORY="$2"
DISCOVERY_PROJECT_NAME="gen-ai-rag-sample-app-project"
DISCOVERY_COLLECTION_NAME="gen-ai-rag-sample-app-data"

# Expects the environment variable $IBMCLOUD_API_KEY to be set
if [[ -z "${IAM_TOKEN}" ]]; then
    echo "API key must be set with IAM_TOKEN environment variable" >&2
    exit 1
fi

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

# Get project ID
PROJECT_ID=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r --arg DISCOVERY_PROJECT_NAME "$DISCOVERY_PROJECT_NAME" '.projects[] | select(.name==$DISCOVERY_PROJECT_NAME) | .project_id ')

# Get collection ID
COLLECTION_ID=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r --arg DISCOVERY_COLLECTION_NAME "$DISCOVERY_COLLECTION_NAME" '.collections[] | select(.name==$DISCOVERY_COLLECTION_NAME) | .collection_id ')

# Check if documents already exist
EXISTING_DOCUMENTS_ARRAY=()
EXISTING_DOCUMENTS=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections/$COLLECTION_ID/documents?status=available&version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.documents[] | .document_id' )
EXISTING_DOCUMENTS_ARRAY=("$EXISTING_DOCUMENTS")
EXISTING_DOCUMENT_NAMES=()

if [[ -z "${EXISTING_DOCUMENTS_ARRAY[*]}" ]]; then
    echo "Documents list is empty, skipping"
else
    for doc in "${EXISTING_DOCUMENTS_ARRAY[@]}"; do
        DOCUMENT_NAME=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections/$COLLECTION_ID/documents/$doc?status=available&version=2023-03-31" \
        --header "Authorization: Bearer $token" \
        --header "Content-Type: application/json" \
        | jq -r '.filename' )
        EXISTING_DOCUMENT_NAMES+=("${DOCUMENT_NAME}")
    done
fi

# Upload documents if they don't exist in the collection already
for i in {1..7};
do
    if ! [[ ${EXISTING_DOCUMENT_NAMES[*]} =~ FAQ-$i.pdf ]]; then
        curl -X POST -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$PROJECT_ID/collections/$COLLECTION_ID/documents?version=2023-03-31" \
        --header "Authorization: Bearer $token" \
        --form "file=@$ARTIFACT_DIRECTORY/FAQ-$i.pdf" \
        --form metadata="{\"field_name\": \"text\"}"
    else
        echo "Document FAQ-$i.pdf already exists, skipping..."
    fi
done
