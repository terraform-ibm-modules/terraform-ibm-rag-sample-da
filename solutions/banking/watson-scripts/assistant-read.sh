#!/usr/bin/env bash

set -e

project_name="gen-ai-rag-sample-app-assistant"
token=$(curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$API_KEY" | jq -r '.access_token')

curl -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
  --header "Authorization: Bearer $token" \
  --header "Content-Type: application/json" | jq -r '.assistants[] | select(.name == "'$project_name'")'
