#!/usr/bin/env bash

set -e

WATSON_DISCOVERY_URL="$1"
WATSON_DISCOVERY_PROJECT_ID="$2"
WATSON_DISCOVERY_COLLECTION_ID="$3"
ARTIFACT_DIRECTORY="$4"

# Expects the environment variable $IBMCLOUD_API_KEY to be set
if [[ -z "${IAM_TOKEN}" ]]; then
    echo "API key must be set with IAM_TOKEN environment variable" >&2
    exit 1
fi

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

# Check if documents already exist
DISCOVERY_QUERY_RESULTS=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$WATSON_DISCOVERY_COLLECTION_ID/documents?status=available&version=2023-03-31" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.documents[] | .document_id' )

# shellcheck disable=SC2206
EXISTING_DOCUMENTS=($DISCOVERY_QUERY_RESULTS)

if [[ ${#EXISTING_DOCUMENTS[@]} -eq 0 ]]; then
    echo "Documents list is empty, skipping"
else
    for doc in "${EXISTING_DOCUMENTS[@]}"; do
        DOCUMENT_NAME=$(curl -X GET --retry 3 -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$WATSON_DISCOVERY_COLLECTION_ID/documents/$doc?status=available&version=2023-03-31" \
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
        curl -X POST -fLsS --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$WATSON_DISCOVERY_COLLECTION_ID/documents?version=2023-03-31" \
        --header "Authorization: Bearer $token" \
        --form "file=@$ARTIFACT_DIRECTORY/FAQ-$i.pdf" \
        --form metadata="{\"field_name\": \"text\"}"
    else
        echo "Document FAQ-$i.pdf already exists, skipping..."
    fi
done
