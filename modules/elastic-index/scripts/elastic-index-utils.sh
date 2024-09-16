#!/usr/bin/env bash

function create_index() {
    local OUTPUT
    # Skip -f
    OUTPUT=$(curl -LsS -X PUT --location "$ELASTIC_URL/$ELASTIC_INDEX_NAME" \
    --header "Authorization: Basic $ELASTIC_AUTH_BASE64" \
    --header "Accepts: application/json" \
    --cacert <(cat <<< "$ELASTIC_CACERT" | base64 -d) )
    check_error "$OUTPUT"
    # Read index attributes
    get_index "$ELASTIC_INDEX_NAME"
}

function read_index() {
    IN=$(cat)
    local existing_index_name
    existing_index_name="$(echo "$IN" | jq -r '.index_name')"
    if [[ -z "$existing_index_name" ]]; then
        exit 0
    fi
    get_index "$existing_index_name"
}

function get_index() {
    local existing_index_name
    existing_index_name=$1
    local OUTPUT
    OUTPUT=$(curl -LsS -X GET --location "${ELASTIC_URL}/$existing_index_name" \
    --header "Authorization: Basic $ELASTIC_AUTH_BASE64" \
    --cacert <(cat <<< "$ELASTIC_CACERT" | base64 -d) \
    --header "Accepts: application/json"  )
    check_error "$OUTPUT"
    echo "$OUTPUT" | jq '. | to_entries[] | select( .value.aliases != null )' | jq -S --arg instance_id "$ELASTIC_INSTANCE_ID" '{"instance_id": $instance_id, "index_name": .key, "id": .value.settings.index.uuid}'
}


function delete_index() {
    IN=$(cat)
    local existing_index_name
    existing_index_name=$(echo "$IN" | jq -r '.index_name')
    if [[ -z "$existing_index_name" ]]; then
        exit 0
    fi
    local OUTPUT
    OUTPUT=$(curl -LsS -X DELETE --location "$ELASTIC_URL/$existing_index_name" \
    --header "Authorization: Basic $ELASTIC_AUTH_BASE64" \
    --header "Accepts: application/json" \
    --cacert <(cat <<< "$ELASTIC_CACERT" | base64 -d) )
    check_error "$OUTPUT"
    echo "$OUTPUT" | jq '. | select( .acknowledged == true )'
}

function create_index_entries() {
    local OUTPUT

    OUTPUT=$(curl -LsS -X POST --location "$ELASTIC_URL/$ELASTIC_INDEX_NAME/_bulk" \
    --header "Authorization: Basic $ELASTIC_AUTH_BASE64" \
    --header "Content-Type: application/json" \
    --header "Accepts: application/json" \
    --data-binary @<(jq -r '.[] | tojson | ("{\"index\" : {} }\n" + .)' < "$ELASTIC_ENTRIES_FILE") \
    --cacert <(cat <<< "$ELASTIC_CACERT" | base64 -d)
     )
    check_error "$OUTPUT"
    if [[ $(echo "$OUTPUT" | jq -r '. | .errors') == "true" ]]; then
        echo "$OUTPUT" | jq '[.items[] | select( .index?.error != null ) | .index]'
        exit 1
    fi
    echo "$OUTPUT" | jq '{ "count": (.items | length) }'
}

function delete_index_entries() {
    local OUTPUT

    OUTPUT=$(curl -LsS -X POST --location "$ELASTIC_URL/$ELASTIC_INDEX_NAME/_delete_by_query?conflicts=proceed" \
    --header "Authorization: Basic $ELASTIC_AUTH_BASE64" \
    --header "Content-Type: application/json" \
    --header "Accepts: application/json" \
    --data '{"query": {"match_all": {}}}' \
    --cacert <(cat <<< "$ELASTIC_CACERT" | base64 -d)
     )
    check_error "$OUTPUT" "index_not_found_exception"
    if [[ ! $(echo "$OUTPUT" | jq -r '.error?.type') ==  "index_not_found_exception" ]]; then
        echo "Index already deleted"
        exit 0
    fi

    if [[ ! $(echo "$OUTPUT" | jq -r '. | .failures | length') == "0" ]]; then
        echo "$OUTPUT"
        exit 1
    fi
}

function check_error() {
    status=$?
    if [ $status -ne 0 ]; then
        echo "API call returned an error code $status"
        echo "$1"
        exit 1
    fi

    local error
    local ignore_error_type
    ignore_error_type="${2:-none}"
    error=$(echo "$1" | jq --arg ignore "$ignore_error_type" '.error | select(.type != $ignore)')
    if [[ -n "$error" && ! "$error" == "null" ]]; then
        echo "$error" | jq
        exit 1
    fi
}
