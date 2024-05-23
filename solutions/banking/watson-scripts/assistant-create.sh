#!/usr/bin/env bash

set -e

project_name="gen-ai-rag-sample-app-assistant"
token=$(curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' -H 'Content-Type: application/x-www-form-urlencoded' -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$API_KEY" | jq -r '.access_token')

ASSISTANT_ID=$(curl --retry 3 -fLsS -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.assistants[] | select(.name == "'$project_name'") | .assistant_id ')

if [[ -z "$ASSISTANT_ID" ]]; then
  # if ASSISTANT_ID is not found then create a new assistant project
  curl --retry 3 -fLsS -X POST --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json" \
      --data "{\"name\":\"$project_name\",\"language\":\"en\",\"description\":\"Generative AI sample app assistant\"}"
else
  # If ASSISTANT_ID exists in a project then do not create another project.
  echo "$project_name project already exists."
  exit 0
fi
