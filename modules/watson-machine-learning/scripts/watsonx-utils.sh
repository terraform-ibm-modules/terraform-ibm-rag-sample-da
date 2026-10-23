#!/usr/bin/env bash
# Helper functions for the watsonx.ai project and storage delegation lifecycle.
# Sourced by the shell_script resources in main.tf. Expected environment variables:
#   IBMCLOUD_API_KEY          API key used to get an IAM token (sensitive)
#   DATAPLATFORM_API_URL      https://api.<region>.dataplatform.cloud.ibm.com (project functions)
#   DATAPLATFORM_UI_URL       https://<region>.dataplatform.cloud.ibm.com (storage delegation functions)
#   PROJECT_NAME              project name
#   PROJECT_CREATE_BODY       JSON body for project creation
#   PROJECT_UPDATE_BODY       JSON body for project update
#   COS_INSTANCE_GUID         COS instance GUID (storage delegation functions)
#   STORAGE_DELEGATION_BODY   JSON body for the storage delegation (storage delegation functions)

set -e

get_token() {
  curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBMCLOUD_API_KEY" | jq -r '.access_token'
}

# usage: http_status <method> <url> [json body] -> prints the status code only
http_status() {
  local method="$1" url="$2" body="${3:-}"
  if [[ -n "$body" ]]; then
    curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X "$method" --location "$url" \
      --header "Authorization: Bearer $token" --header "Content-Type: application/json" --data "$body"
  else
    curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X "$method" --location "$url" \
      --header "Authorization: Bearer $token" --header "Content-Type: application/json"
  fi
}

project_output() {
  jq -nS --arg project_id "$1" --arg name "$2" '{"project_id": $project_id, "name": $name}'
}

# ---------------------------------------------------------------------------
# watsonx.ai project
# ---------------------------------------------------------------------------

# Create the project, or adopt an existing project with the same name
create_project() {
  token=$(get_token)
  local existing_id location project_id
  existing_id=$(curl -fLsS --retry 3 --location "$DATAPLATFORM_API_URL/v2/projects?limit=100" \
    --header "Authorization: Bearer $token" --header "Content-Type: application/json" \
    | jq -r --arg name "$PROJECT_NAME" '[.resources[] | select(.entity.name == $name)][0].metadata.guid // empty')
  if [[ -n "$existing_id" ]]; then
    project_output "$existing_id" "$PROJECT_NAME"
    return
  fi
  location=$(curl -fLsS --retry 3 -X POST --location "$DATAPLATFORM_API_URL/transactional/v2/projects?verify_unique_name=true" \
    --header "Authorization: Bearer $token" --header "Content-Type: application/json" \
    --data "$PROJECT_CREATE_BODY" | jq -r '.location')
  # location looks like /v2/projects/<project id>
  project_id="${location##*/}"
  project_output "$project_id" "$PROJECT_NAME"
}

# Print the current state, or nothing when the project no longer exists (removes it from state)
read_project() {
  token=$(get_token)
  local project_id status
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  status=$(http_status GET "$DATAPLATFORM_API_URL/v2/projects/$project_id")
  if [[ "$status" == "404" ]]; then
    return
  fi
  if [[ "$status" != "200" ]]; then
    echo "Reading watsonx.ai project $project_id failed with HTTP $status" >&2
    exit 1
  fi
  project_output "$project_id" "$PROJECT_NAME"
}

update_project() {
  token=$(get_token)
  local project_id status
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  status=$(http_status PATCH "$DATAPLATFORM_API_URL/v2/projects/$project_id" "$PROJECT_UPDATE_BODY")
  if [[ "$status" != "200" && "$status" != "204" ]]; then
    echo "Updating watsonx.ai project $project_id failed with HTTP $status" >&2
    exit 1
  fi
  project_output "$project_id" "$PROJECT_NAME"
}

delete_project() {
  token=$(get_token)
  local project_id status
  project_id=$(jq -r '.project_id' <<<"$(cat)")
  status=$(http_status DELETE "$DATAPLATFORM_API_URL/transactional/v2/projects/$project_id")
  if [[ "$status" != "204" && "$status" != "200" && "$status" != "202" && "$status" != "404" ]]; then
    echo "Deleting watsonx.ai project $project_id failed with HTTP $status" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Storage delegation (COS instance encrypted with a KMS key, used by watsonx projects)
# ---------------------------------------------------------------------------

delegation_output() {
  jq -nS --arg cos_instance_guid "$COS_INSTANCE_GUID" '{"cos_instance_guid": $cos_instance_guid}'
}

# Create the delegation, or adopt the existing one for the COS instance
create_storage_delegation() {
  token=$(get_token)
  local status
  status=$(http_status GET "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations/$COS_INSTANCE_GUID")
  if [[ "$status" == "200" ]]; then
    # Make sure the existing delegation has the expected settings
    status=$(http_status PATCH "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations/$COS_INSTANCE_GUID" "$STORAGE_DELEGATION_BODY")
    if [[ "$status" != "200" && "$status" != "204" ]]; then
      echo "Updating the storage delegation for $COS_INSTANCE_GUID failed with HTTP $status" >&2
      exit 1
    fi
    delegation_output
    return
  fi
  status=$(http_status POST "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations" "$STORAGE_DELEGATION_BODY")
  if [[ "$status" != "200" && "$status" != "201" ]]; then
    echo "Creating the storage delegation for $COS_INSTANCE_GUID failed with HTTP $status" >&2
    exit 1
  fi
  delegation_output
}

read_storage_delegation() {
  token=$(get_token)
  local status
  status=$(http_status GET "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations/$COS_INSTANCE_GUID")
  if [[ "$status" == "404" ]]; then
    return
  fi
  if [[ "$status" != "200" ]]; then
    echo "Reading the storage delegation for $COS_INSTANCE_GUID failed with HTTP $status" >&2
    exit 1
  fi
  delegation_output
}

update_storage_delegation() {
  token=$(get_token)
  local status
  status=$(http_status PATCH "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations/$COS_INSTANCE_GUID" "$STORAGE_DELEGATION_BODY")
  if [[ "$status" != "200" && "$status" != "204" ]]; then
    echo "Updating the storage delegation for $COS_INSTANCE_GUID failed with HTTP $status" >&2
    exit 1
  fi
  delegation_output
}

delete_storage_delegation() {
  token=$(get_token)
  local status
  status=$(http_status DELETE "$DATAPLATFORM_UI_URL/api/rest/v1/storage-delegations/$COS_INSTANCE_GUID")
  if [[ "$status" != "200" && "$status" != "204" && "$status" != "404" ]]; then
    echo "Deleting the storage delegation for $COS_INSTANCE_GUID failed with HTTP $status" >&2
    exit 1
  fi
}
