#!/usr/bin/env bash

set -e

# shellcheck disable=SC2154
token="$(echo "$iam_token" | awk '{print $2}')"

# shellcheck disable=SC2154
if [ "$region" == "us-south" ]; then
    dataplatform_api="https://api.dataplatform.cloud.ibm.com"
elif [ "$region" == "eu-gb" ]; then
    dataplatform_api="https://api.eu-gb.dataplatform.cloud.ibm.com"
elif [ "$region" == "eu-de" ]; then
    dataplatform_api="https://api.eu-de.dataplatform.cloud.ibm.com"
elif [ "$region" == "jp-tok" ]; then
    dataplatform_api="https://api.jp-tok.dataplatform.cloud.ibm.com"
elif [ "$region" == "au-syd" ]; then
    dataplatform_api="https://api.au-syd.dai.cloud.ibm.com"
elif [ "$region" == "ca-tor" ]; then
    dataplatform_api="https://api.ca-tor.dai.cloud.ibm.com"
else
    echo "Unknown region" && exit 1
fi

# add the user to watson.ai project as an admin
# shellcheck disable=SC2154
curl -s -X POST --location "$dataplatform_api/v2/projects/$project_id/members" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $token" \
    --data-raw "{
            \"members\": [
                {
                    \"user_name\": \"$user_name\",
                    \"id\": \"$iam_id\",
                    \"role\": \"$role\",
                    \"state\": \"$state\",
                    \"type\": \"$type\"
                }
            ]
        }"
