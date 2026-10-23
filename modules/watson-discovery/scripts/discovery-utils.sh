#!/usr/bin/env bash
# Helper functions for the Watson Discovery project and collection lifecycle.
# Sourced by the shell_script resources in main.tf. Expected environment variables:
#   IBMCLOUD_API_KEY                 API key used to get an IAM token (sensitive)
#   WATSON_DISCOVERY_URL             https://api.<region>.discovery.watson.cloud.ibm.com/instances/<guid>
#   WATSON_DISCOVERY_API_VERSION     API version date, for example 2023-03-31
#   WATSON_DISCOVERY_PROJECT_NAME    project name
#   WATSON_DISCOVERY_PROJECT_ID      project ID (collection functions only)
#   WATSON_DISCOVERY_COLLECTION_NAME collection name (collection functions only)

set -e

get_token() {
  curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBMCLOUD_API_KEY" | jq -r '.access_token'
}

api_call() {
  # usage: api_call <method> <path-and-query> [json body]
  local method="$1" path="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -fLsS --retry 3 -X "$method" --location "$WATSON_DISCOVERY_URL$path" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json" \
      --data "$body"
  else
    curl -fLsS --retry 3 -X "$method" --location "$WATSON_DISCOVERY_URL$path" \
      --header "Authorization: Bearer $token" \
      --header "Content-Type: application/json"
  fi
}

project_output() {
  jq -nS --arg project_id "$1" --arg name "$2" '{"project_id": $project_id, "name": $name}'
}

collection_output() {
  jq -nS --arg collection_id "$1" --arg name "$2" '{"collection_id": $collection_id, "name": $name}'
}

# ---------------------------------------------------------------------------
# Project
# ---------------------------------------------------------------------------

# Create the project, or adopt an existing project with the same name
create_project() {
  token=$(get_token)
  local existing_id
  existing_id=$(api_call GET "/v2/projects?version=$WATSON_DISCOVERY_API_VERSION" \
    | jq -r --arg name "$WATSON_DISCOVERY_PROJECT_NAME" '[.projects[] | select(.name == $name)][0].project_id // empty')
  if [[ -n "$existing_id" ]]; then
    project_output "$existing_id" "$WATSON_DISCOVERY_PROJECT_NAME"
    return
  fi
  local body project_id
  body=$(jq -n --arg name "$WATSON_DISCOVERY_PROJECT_NAME" '{"name": $name, "type": "document_retrieval"}')
  project_id=$(api_call POST "/v2/projects?version=$WATSON_DISCOVERY_API_VERSION" "$body" | jq -r '.project_id')
  project_output "$project_id" "$WATSON_DISCOVERY_PROJECT_NAME"
}

# Print the current state, or nothing when the project no longer exists (removes it from state)
read_project() {
  token=$(get_token)
  local project_id result
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  result=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' --location "$WATSON_DISCOVERY_URL/v2/projects/$project_id?version=$WATSON_DISCOVERY_API_VERSION" \
    --header "Authorization: Bearer $token")
  if [[ "$result" == "404" ]]; then
    return
  fi
  if [[ "$result" != "200" ]]; then
    echo "Reading Discovery project $project_id failed with HTTP $result" >&2
    exit 1
  fi
  # The name is taken from the environment so that a rename shows up as an update
  project_output "$project_id" "$WATSON_DISCOVERY_PROJECT_NAME"
}

# Rename the project in place
update_project() {
  token=$(get_token)
  local project_id body
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  body=$(jq -n --arg name "$WATSON_DISCOVERY_PROJECT_NAME" '{"name": $name}')
  api_call POST "/v2/projects/$project_id?version=$WATSON_DISCOVERY_API_VERSION" "$body" >/dev/null
  project_output "$project_id" "$WATSON_DISCOVERY_PROJECT_NAME"
}

delete_project() {
  token=$(get_token)
  local project_id result
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  result=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X DELETE --location "$WATSON_DISCOVERY_URL/v2/projects/$project_id?version=$WATSON_DISCOVERY_API_VERSION" \
    --header "Authorization: Bearer $token")
  if [[ "$result" != "204" && "$result" != "200" && "$result" != "404" ]]; then
    echo "Deleting Discovery project $project_id failed with HTTP $result" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Collection
# ---------------------------------------------------------------------------

create_collection() {
  token=$(get_token)
  local existing_id
  existing_id=$(api_call GET "/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections?version=$WATSON_DISCOVERY_API_VERSION" \
    | jq -r --arg name "$WATSON_DISCOVERY_COLLECTION_NAME" '[.collections[] | select(.name == $name)][0].collection_id // empty')
  if [[ -n "$existing_id" ]]; then
    collection_output "$existing_id" "$WATSON_DISCOVERY_COLLECTION_NAME"
    return
  fi
  local body collection_id
  body=$(jq -n --arg name "$WATSON_DISCOVERY_COLLECTION_NAME" '{"name": $name, "description": "Sample data"}')
  collection_id=$(api_call POST "/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections?version=$WATSON_DISCOVERY_API_VERSION" "$body" | jq -r '.collection_id')
  collection_output "$collection_id" "$WATSON_DISCOVERY_COLLECTION_NAME"
}

read_collection() {
  token=$(get_token)
  local collection_id result
  collection_id=$(jq -r '.collection_id' <<<"$(cat)")
  result=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$collection_id?version=$WATSON_DISCOVERY_API_VERSION" \
    --header "Authorization: Bearer $token")
  if [[ "$result" == "404" ]]; then
    return
  fi
  if [[ "$result" != "200" ]]; then
    echo "Reading Discovery collection $collection_id failed with HTTP $result" >&2
    exit 1
  fi
  collection_output "$collection_id" "$WATSON_DISCOVERY_COLLECTION_NAME"
}

# Rename the collection in place. If the project was re-created and the collection is gone, create it again.
update_collection() {
  token=$(get_token)
  local collection_id body result
  collection_id=$(jq -r '.collection_id' <<<"$(cat)")
  result=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$collection_id?version=$WATSON_DISCOVERY_API_VERSION" \
    --header "Authorization: Bearer $token")
  if [[ "$result" == "404" ]]; then
    create_collection
    return
  fi
  body=$(jq -n --arg name "$WATSON_DISCOVERY_COLLECTION_NAME" '{"name": $name, "description": "Sample data"}')
  api_call POST "/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$collection_id?version=$WATSON_DISCOVERY_API_VERSION" "$body" >/dev/null
  collection_output "$collection_id" "$WATSON_DISCOVERY_COLLECTION_NAME"
}

delete_collection() {
  token=$(get_token)
  local collection_id result
  collection_id=$(jq -r '.collection_id' <<<"$(cat)")
  result=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X DELETE --location "$WATSON_DISCOVERY_URL/v2/projects/$WATSON_DISCOVERY_PROJECT_ID/collections/$collection_id?version=$WATSON_DISCOVERY_API_VERSION" \
    --header "Authorization: Bearer $token")
  if [[ "$result" != "204" && "$result" != "200" && "$result" != "404" ]]; then
    echo "Deleting Discovery collection $collection_id failed with HTTP $result" >&2
    exit 1
  fi
}
