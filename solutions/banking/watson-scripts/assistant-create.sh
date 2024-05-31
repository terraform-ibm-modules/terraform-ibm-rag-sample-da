#!/usr/bin/env bash

set -e
token=$(curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBMCLOUD_API_KEY" | jq -r '.access_token')

OUTPUT=$(curl --retry 3 -fLsS -X POST --location "$WATSON_ASSISTANT_URL/v2/assistants?version=$WATSON_ASSISTANT_API_VERSION" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "{\"name\":\"$WATSON_ASSISTANT_NAME\",\"language\":\"$WATSON_ASSISTANT_LANGUAGE\",\"description\":\"$WATSON_ASSISTANT_DESCRIPTION\"}")

ASSISTANT_ID=$(echo "$OUTPUT" | jq -r '.assistant_id')
ENVIRONMENT_ID=$(echo "$OUTPUT" | jq -r '.assistant_environments[] | select(.name == "draft") | .environment_id')

INTEGRATION_ID=$(curl -X GET -retry 3 -flsS --location "$WATSON_ASSISTANT_URL/v2/assistants/$ASSISTANT_ID/environments/$ENVIRONMENT_ID?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.integration_references[] | select(.type == "web_chat") | .integration_id ')

jq -nS --arg assistant_id "$ASSISTANT_ID" --arg assistant_integration_id "$INTEGRATION_ID" '{"assistant_integration_id": $assistant_integration_id, "assistant_id": $assistant_id}'
