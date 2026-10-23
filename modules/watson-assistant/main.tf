locals {
  watson_assistant_api_version = "2023-06-15"
  watson_assistant_name        = try("${local.prefix}-gen-ai-rag-sample-app-assistant", "gen-ai-rag-sample-app-assistant")
  prefix                       = var.prefix != null ? (var.prefix != "" ? var.prefix : null) : null

  # Base URL of the assistant that is created by the shell_script resource below
  assistant_api_url = "https:${var.watsonx_assistant_url}/v2/assistants/${shell_script.watson_assistant.output.assistant_id}"
  api_headers = {
    Authorization  = var.sensitive_tokendata
    "Content-Type" = "application/json"
  }

  # Pick the target environment (for example "draft") from the environment list
  watsonx_assistant_environment  = [for env in jsondecode(data.http.get_assistant_environment.response_body).environments : env if env.name == var.assistant_environment][0]
  assistant_environment_id       = local.watsonx_assistant_environment.environment_id
  assistant_environment_api_path = "${local.assistant_api_url}/environments/${local.assistant_environment_id}?version=${local.watson_assistant_api_version}"
  assistant_skills               = [for skill in local.watsonx_assistant_environment.skill_references : skill.type == "search" ? merge(skill, { "disabled" : false }) : skill]
  assistant_skills_map           = { for skill in local.watsonx_assistant_environment.skill_references : skill.type => skill.skill_id }
  assistant_search_skill         = var.assistant_search_skill != null ? { search_settings = merge(jsondecode(var.assistant_search_skill).search_settings, { elastic_search = merge(var.elastic_service_binding, { "index" : var.elastic_index_name }) }) } : null
  assistant_action_skill         = var.assistant_action_skill != null ? jsondecode(var.assistant_action_skill) : null

  # The environment after the skill references update, in the same shape as the data source above
  watsonx_assistant_environment_after_update = [for env in jsondecode(data.http.get_assistant_environment_after_update.response_body).environments : env if env.name == var.assistant_environment][0]
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
    WATSON_ASSISTANT_NAME        = local.watson_assistant_name
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

# Look up the assistant environments and pick the target one by name
data "http" "get_assistant_environment" {
  url             = "${local.assistant_api_url}/environments?version=${local.watson_assistant_api_version}"
  request_headers = local.api_headers

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Listing the assistant environments failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

# Assistant Search skill update
# The http provider only has a data source, so this POST runs on every plan and apply.
# The call is idempotent: it sets the same search settings each time.
data "http" "assistant_search_skill" {
  count           = var.assistant_search_skill != null ? 1 : 0
  url             = "${local.assistant_api_url}/skills/${local.assistant_skills_map.search}?version=${local.watson_assistant_api_version}"
  method          = "POST"
  request_headers = local.api_headers
  request_body    = jsonencode(local.assistant_search_skill)

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 202], self.status_code)
      error_message = "Updating the assistant search skill failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

# Assistant Action skill import
# Idempotent: the same skill definition is imported each time.
data "http" "assistant_action_skill" {
  count           = var.assistant_action_skill != null ? 1 : 0
  url             = "${local.assistant_api_url}/skills_import?version=${local.watson_assistant_api_version}"
  method          = "POST"
  request_headers = local.api_headers
  request_body    = sensitive(jsonencode(local.assistant_action_skill))

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 202], self.status_code)
      error_message = "Importing the assistant action skill failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

resource "time_sleep" "wait_60_seconds" { # tflint-ignore: terraform_required_providers
  depends_on      = [data.http.assistant_search_skill, data.http.assistant_action_skill]
  create_duration = "60s"
}

# Assistant skill references update - enable search skill
data "http" "assistant_skills_references" {
  count           = var.assistant_search_skill != null ? 1 : 0 # Only need to update it if the search skill was updated
  depends_on      = [time_sleep.wait_60_seconds]
  url             = local.assistant_environment_api_path
  method          = "POST"
  request_headers = local.api_headers
  request_body    = jsonencode({ "skill_references" : local.assistant_skills })

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = contains([200, 201, 202], self.status_code)
      error_message = "Updating the assistant skill references failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}

data "http" "get_assistant_environment_after_update" {
  depends_on      = [data.http.assistant_skills_references]
  url             = "${local.assistant_api_url}/environments?version=${local.watson_assistant_api_version}"
  request_headers = local.api_headers

  retry {
    attempts     = 3
    min_delay_ms = 2000
  }

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Listing the assistant environments failed with HTTP ${self.status_code}: ${self.response_body}"
    }
  }
}
