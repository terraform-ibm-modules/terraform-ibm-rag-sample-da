locals {
  watson_assistant_api_version   = "2023-06-15"
  watsonx_assistant_environment  = jsondecode(data.restapi_object.get_assistant_environment.api_response)
  assistant_environment_api_path = "${var.watsonx_assistant_url}/v2/assistants/${shell_script.watson_assistant.output.assistant_id}/environments/${data.restapi_object.get_assistant_environment.id}"
  assistant_skills_api_path      = "${var.watsonx_assistant_url}/v2/assistants/${shell_script.watson_assistant.output.assistant_id}"
  assistant_skills               = [for skill in local.watsonx_assistant_environment.skill_references : skill.type == "search" ? merge(skill, { "disabled" : false }) : skill]
  assistant_skills_map           = { for skill in local.watsonx_assistant_environment.skill_references : skill.type => skill.skill_id }
  assistant_search_skill         = var.assistant_search_skill != null ? { search_settings = merge(jsondecode(var.assistant_search_skill).search_settings, { elastic_search = merge(var.elastic_service_binding, { "index" : var.elastic_index_name }) }) } : null
  assistant_action_skill         = var.assistant_action_skill != null ? jsondecode(var.assistant_action_skill) : null
}

# assistant creation
resource "shell_script" "watson_assistant" {
  lifecycle_commands {
    create = file("${path.module}/scripts/assistant-create.sh")
    delete = file("${path.module}/scripts/assistant-destroy.sh")
    read   = file("${path.module}/scripts/assistant-read.sh")
  }

  environment = {
    WATSON_ASSISTANT_API_VERSION = local.watson_assistant_api_version
    WATSON_ASSISTANT_DESCRIPTION = "Generative AI sample app assistant"
    WATSON_ASSISTANT_LANGUAGE    = "en"
    WATSON_ASSISTANT_NAME        = var.prefix != "" ? "${var.prefix}-gen-ai-rag-sample-app-assistant" : "gen-ai-rag-sample-app-assistant"
    WATSON_ASSISTANT_URL         = "https:${var.watsonx_assistant_url}"
  }

  sensitive_environment = {
    IBMCLOUD_API_KEY = var.watsonx_admin_api_key
  }

  # Change in apikey should not trigger assistant re-create
  lifecycle {
    ignore_changes = [sensitive_environment]
  }
}


data "restapi_object" "get_assistant_environment" {
  provider     = restapi.restapi_watsonx_admin
  path         = "${var.watsonx_assistant_url}/v2/assistants/${shell_script.watson_assistant.output.assistant_id}/environments"
  query_string = "version=${local.watson_assistant_api_version}"
  results_key  = "environments"
  search_key   = "name"
  search_value = var.assistant_environment
  id_attribute = "environment_id"
}

# Assistant Search skill update
resource "restapi_object" "assistant_search_skill" {
  count          = var.assistant_search_skill != null ? 1 : 0
  provider       = restapi.restapi_watsonx_admin
  path           = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.search}"
  query_string   = "version=${local.watson_assistant_api_version}"
  read_path      = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.search}"
  read_method    = "GET"
  create_path    = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.search}"
  create_method  = "POST"
  id_attribute   = "skill_id"
  destroy_method = "GET" # There is no destroy operation on default search skill
  destroy_path   = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.search}"
  destroy_data   = "{}"
  data           = jsonencode(local.assistant_search_skill)
  update_method  = "POST"
  update_path    = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.search}"
  update_data    = jsonencode(local.assistant_search_skill)
}

# Assistant Action skill import
resource "restapi_object" "assistant_action_skill" {
  count          = var.assistant_action_skill != null ? 1 : 0
  provider       = restapi.restapi_watsonx_admin
  path           = "${local.assistant_skills_api_path}/skills_import"
  query_string   = "version=${local.watson_assistant_api_version}"
  read_path      = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.action}"
  read_method    = "GET"
  create_path    = "${local.assistant_skills_api_path}/skills_import"
  create_method  = "POST"
  id_attribute   = "assistant_id" # The only attribute returned from skills_import call
  destroy_method = "GET"          # There is no destroy operation on default action skill
  destroy_path   = "${local.assistant_skills_api_path}/skills/${local.assistant_skills_map.action}"
  destroy_data   = "{}"
  data           = sensitive(jsonencode(local.assistant_action_skill))
  update_method  = "POST"
  update_path    = "${local.assistant_skills_api_path}/skills_import"
  update_data    = sensitive(jsonencode(local.assistant_action_skill))
}

resource "time_sleep" "wait_30_seconds" { # tflint-ignore: terraform_required_providers
  depends_on      = [restapi_object.assistant_search_skill, restapi_object.assistant_action_skill]
  create_duration = "30s"
}

# Assistant skill references update - enable search skill
resource "restapi_object" "assistant_skills_references" {
  count          = var.assistant_search_skill != null ? 1 : 0 # Only need to update it if the search skill was updated
  depends_on     = [time_sleep.wait_30_seconds]
  provider       = restapi.restapi_watsonx_admin
  path           = local.assistant_environment_api_path
  query_string   = "version=${local.watson_assistant_api_version}"
  data           = jsonencode({ "skill_references" : local.assistant_skills })
  id_attribute   = "environment_id"
  read_path      = local.assistant_environment_api_path
  read_method    = "GET"
  create_path    = local.assistant_environment_api_path
  create_method  = "POST"
  destroy_path   = local.assistant_environment_api_path
  destroy_method = "POST"
  destroy_data   = jsonencode({ "skill_references" : local.assistant_skills })
  update_path    = local.assistant_environment_api_path
  update_method  = "POST"
  update_data    = jsonencode({ "skill_references" : local.assistant_skills })
}

data "restapi_object" "get_assistant_environment_after_update" {
  provider     = restapi.restapi_watsonx_admin
  depends_on   = [restapi_object.assistant_skills_references]
  path         = "${var.watsonx_assistant_url}/v2/assistants/${shell_script.watson_assistant.output.assistant_id}/environments"
  query_string = "version=${local.watson_assistant_api_version}"
  results_key  = "environments"
  search_key   = "name"
  search_value = var.assistant_environment
  id_attribute = "environment_id"
}
