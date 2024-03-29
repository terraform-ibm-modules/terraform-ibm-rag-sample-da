locals {
  watsonx_assistant_url = "https://api.${var.watson_assistant_region}.assistant.watson.cloud.ibm.com/instances/${var.watson_assistant_instance_id}"
  watsonx_discovery_url = "https://api.${var.watson_discovery_region}.discovery.watson.cloud.ibm.com/instances/${var.watson_discovery_instance_id}"
}

# discovery project creation
resource "null_resource" "discovery_project_creation" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_discovery_url = local.watsonx_discovery_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      curl -X POST -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json" \
        --data "{   \"name\": \"Customer Care - Bank Loans - v1\",   \"type\": \"document_retrieval\" }" "${local.watsonx_discovery_url}/v2/projects?version=2023-03-31"
    EOF
  }
}

# discovery collection creation
resource "null_resource" "discovery_collection_creation" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_discovery_url = local.watsonx_discovery_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      PROJECT_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json"  "${local.watsonx_discovery_url}/v2/projects?version=2023-03-31" \
      | jq '.projects[] | select(.name == "Customer Care - Bank Loans - v1") | .project_id '")

      curl -X POST -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json" --data \
        "{ \"name\": \"Bank Loans FAQs - v1\",   \"description\": \"Instructional PDFs\" }" \
        "${local.watsonx_discovery_url}/v2/projects/$PROJECT_ID/collections?version=2023-03-31"
    EOF
  }
}

# discovery file upload
resource "null_resource" "discovery_file_upload" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_discovery_url = local.watsonx_discovery_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      PROJECT_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json"  "${local.watsonx_discovery_url}/v2/projects?version=2023-03-31" \
      | jq '.projects[] | select(.name == "Customer Care - Bank Loans - v1") | .project_id '")

      COLLECTION_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" \
        "${local.watsonx_discovery_url}/v2/projects/$PROJECT_ID/collections?version=2023-03-31" \
        | jq '.collections[] | select(.name == "Bank Loans FAQs - v1") | .collection_id ')

      for i in {1..7};
      do
        curl -X POST -u "apikey:${var.ibmcloud_api_key}" --form "file=@./artifacts/WatsonDiscovery/FAQ-$i.pdf" \
          --form metadata="{\"field_name\": \"text"}" \
          "${local.watsonx_discovery_url}/v2/projects/$PROJECT_ID/collections/$COLLECTION_ID/documents?version=2023-03-31" \
      done
    EOF
  }
}

# assistant project creation
resource "null_resource" "assistant_project_creation" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_assistant_url = local.watsonx_assistant_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      curl -X POST -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json" \
        --data "{\"name\":\"cc-bank-loan-demo-v1\",\"language\":\"en\",\"description\":\"Bank loan demo assistant\"}" \
        "${local.watsonx_assistant_url}/v2/assistants?version=2023-06-15"
    EOF
  }
}

# assistant skills import
resource "null_resource" "assistant_import_rag_pattern_action_skill" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_assistant_url = local.watsonx_assistant_url
  }

  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      ASSISTANT_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" "${local.watsonx_assistant_url}/v2/assistants?version=2023-06-15" \
        | jq '.assistants[] | select(.name == "cc bank loan v1") | .assistant_id ')

      curl -X POST -u "apikey:${var.ibmcloud_api_key}" --header "Content-Type: application/json" \
         --data "@./artifacts/watsonX.Assistant/cc-bank-loan-v1-action.json" \
         "${local.watsonx_assistant_url}/v2/assistants/$ASSISTANT_ID/skills_import?version=2023-06-15"
    EOF
  }
}

# get assistant integration ID
resource "null_resource" "assistant_retrieve_integration_id" {
  triggers = {
    always_run            = timestamp()
    ibmcloud_api_key      = var.ibmcloud_api_key
    watsonx_assistant_url = local.watsonx_assistant_url
  }

  # put in local file for now - need to develop more sophisticated method for grabbing integration ID
  provisioner "local-exec" {
    command = <<EOF
      #!/bin/bash
      ASSISTANT_ID=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" "${local.watsonx_assistant_url}/v2/assistants?version=2023-06-15" \
        | jq '.assistants[] | select(.name == "cc bank loan v1") | .assistant_id ')

      ENVIRONMENT_OUTPUT=$(curl -X GET -u "apikey:${var.ibmcloud_api_key}" "${local.watsonx_assistant_url}/v2/assistants/$ASSISTANT_ID/environments?version=2023-06-15" \
        | jq '.environments[] | select(.name == "draft") ')
      echo $ENVIRONMENT_OUTPUT | jq '.integration_references[] | select(.type == "web_chat") | .integration_id ' >> .integration_id
    EOF
  }
}

# Update CI pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_ci" {
  name        = "watsonx_assistant_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CD pipeline with Assistant instance ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_id_pipeline_property_cd" {
  name        = "watsonx_assistant_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = var.watson_assistant_instance_id
}

# Update CI pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_ci" {
  name        = "app-flavor"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CD pipeline with app flavor
resource "ibm_cd_tekton_pipeline_property" "application_flavor_pipeline_property_cd" {
  name        = "app-flavor"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = "banking"
}

# Update CI pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_ci" {
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.ci_pipeline_id
  type        = "text"
  value       = file("./.integration_id")
}

# Update CD pipeline with Assistant integration ID
resource "ibm_cd_tekton_pipeline_property" "watsonx_assistant_integration_id_pipeline_property_cd" {
  name        = "watsonx_assistant_integration_id"
  pipeline_id = var.cd_pipeline_id
  type        = "text"
  value       = file("./.integration_id")
}
