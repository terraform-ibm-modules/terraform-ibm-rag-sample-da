#!/usr/bin/env bash

set -e

token=$(curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBMCLOUD_API_KEY" | jq -r '.access_token')

IN=$(cat)
EXISTING_ASSISTANT_ID=$(echo "$IN" | jq -r .assistant_id)

OUTPUT=$(curl -flsS --retry 3 -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=$WATSON_ASSISTANT_API_VERSION" \
  --header "Authorization: Bearer $token" \
  --header "Content-Type: application/json" | jq -r '.assistants[] | select(.assistant_id == "'"$EXISTING_ASSISTANT_ID"'")')

if [[ $OUTPUT ]]; then
  curl -fLsS -X DELETE --location "$WATSON_ASSISTANT_URL/v2/assistants/$EXISTING_ASSISTANT_ID?version=$WATSON_ASSISTANT_API_VERSION" \
      --header "Authorization: Bearer $token"
fi
