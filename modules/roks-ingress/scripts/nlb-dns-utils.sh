#!/usr/bin/env bash
# Helper functions for the NLB DNS entry lifecycle of the public ingress.
# Sourced by the shell_script resource in main.tf. Expected environment variables:
#   IBMCLOUD_API_KEY   API key used to get an IAM token (sensitive)
#   CONTAINERS_API_URL https://containers.cloud.ibm.com/global
#   CLUSTER_NAME       cluster name or ID
#   LB_HOSTNAME        load balancer hostname the new NLB DNS entry points to at creation time

set -e

get_token() {
  curl -fLsS -X POST 'https://iam.cloud.ibm.com/identity/token' \
    -H 'Content-Type: application/x-www-form-urlencoded' \
    -d "grant_type=urn:ibm:params:oauth:grant-type:apikey&apikey=$IBMCLOUD_API_KEY" | jq -r '.access_token'
}

nlb_output() {
  jq -nS --arg nlb_subdomain "$1" --arg cluster_id "$2" '{"nlb_subdomain": $nlb_subdomain, "cluster_id": $cluster_id}'
}

# Create an NLB DNS entry. It picks the next NLB DNS index for the name like
# <cluster name>-<guid>-<NLB DNS index>.<region>.containers.appdomain.cloud
create_nlb_dns() {
  token=$(get_token)
  local body response
  body=$(jq -n --arg cluster "$CLUSTER_NAME" --arg lb "$LB_HOSTNAME" \
    '{"cluster": $cluster, "dnsType": "public", "lbHostname": $lb, "secretNamespace": "openshift-ingress", "type": "public"}')
  response=$(curl -fLsS --retry 3 -X POST --location "$CONTAINERS_API_URL/v2/nlb-dns/vpc/createNlbDNS" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "$body")
  # The create and read API responses have different structures
  nlb_output "$(jq -r '.Nlb.nlbSubdomain // .nlbSubdomain' <<<"$response")" "$(jq -r '.Nlb.cluster // .cluster' <<<"$response")"
}

# Print the current state, or nothing when the entry no longer exists (removes it from state)
read_nlb_dns() {
  token=$(get_token)
  local in subdomain response status body
  in=$(cat)
  subdomain=$(jq -r '.nlb_subdomain' <<<"$in")
  response=$(curl -LsS --retry 3 -w '\n%{http_code}' --location "$CONTAINERS_API_URL/v2/nlb-dns/getNlbDetails?cluster=$CLUSTER_NAME&nlbSubdomain=$subdomain" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json")
  status=$(tail -n1 <<<"$response")
  body=$(sed '$d' <<<"$response")
  if [[ "$status" == "404" ]] || [[ "$status" == "200" && -z "$(jq -r '.nlbSubdomain // empty' <<<"$body")" ]]; then
    return
  fi
  if [[ "$status" != "200" ]]; then
    echo "Reading NLB DNS entry $subdomain failed with HTTP $status: $body" >&2
    exit 1
  fi
  nlb_output "$(jq -r '.nlbSubdomain' <<<"$body")" "$(jq -r '.cluster' <<<"$body")"
}

# Remove the ALB assignment from the NLB DNS entry and delete the TLS secret.
# The domain must be removed through the ingress/v2/dns API, otherwise the NLB DNS entry is not deleted.
delete_nlb_dns() {
  token=$(get_token)
  local in subdomain body status
  in=$(cat)
  subdomain=$(jq -r '.nlb_subdomain' <<<"$in")
  body=$(jq -n --arg cluster "$CLUSTER_NAME" --arg subdomain "$subdomain" '{"cluster": $cluster, "subdomain": $subdomain}')
  status=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X POST --location "$CONTAINERS_API_URL/ingress/v2/dns/deleteDomain" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "$body")
  if [[ "$status" != "200" && "$status" != "204" && "$status" != "404" ]]; then
    echo "Deleting NLB DNS domain $subdomain failed with HTTP $status" >&2
    exit 1
  fi
  status=$(curl -LsS --retry 3 -o /dev/null -w '%{http_code}' -X POST --location "$CONTAINERS_API_URL/v2/nlb-dns/deleteSecret" \
    --header "Authorization: Bearer $token" \
    --header "Content-Type: application/json" \
    --data "$body")
  if [[ "$status" != "200" && "$status" != "204" && "$status" != "404" ]]; then
    echo "Deleting the TLS secret for $subdomain failed with HTTP $status" >&2
    exit 1
  fi
}
