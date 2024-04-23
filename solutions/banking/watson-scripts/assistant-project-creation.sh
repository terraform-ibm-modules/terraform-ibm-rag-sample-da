#!/usr/bin/env bash
set -e

IAM_TOKEN="$1"
WATSON_ASSISTANT_URL=$2
project_name="gen-ai-rag-sample-app-assistant"

token="$(echo "$IAM_TOKEN" | awk '{print $2}')"

ASSISTANT_ID=$(curl --retry 3 -fLsS -X GET --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    | jq -r '.assistants[] | select(.name == "'$project_name'") | .assistant_id ')

if [[ -z "$ASSISTANT_ID" ]]; then
  # if not ASSISTANT_ID is found then create a new assistant project
  curl --retry 3 -fLsS -X POST --location "$WATSON_ASSISTANT_URL/v2/assistants?version=2023-06-15" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json" \
      --data "{\"name\":\"$project_name\",\"language\":\"en\",\"description\":\"Generative AI sample app assistant\"}"
else
  # If ASSISTANT_ID exists in a project then do not create another project.
  echo "$project_name project already exists."
  exit 0
fi
