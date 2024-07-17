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
    local existing_index_name=$(echo $IN | jq -r '.index_name')
    if [[ -z "$existing_index_name" ]]; then
        exit 0
    fi
    get_index "$existing_index_name"
}

function get_index() {
    local existing_index_name=$1
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
    local existing_index_name=$(echo $IN | jq -r '.index_name')
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

function check_error() {
    status=$?
    if [ $status -ne 0 ]; then
        echo "API call returned an error code $status"
        echo "$1"
        exit 1
    fi

    local error=$(echo "$1" | jq '.error')
    if [[ ! -z "$error" && ! "$error" == "null" ]]; then
        echo "$error" | jq
        exit 1
    fi
}
