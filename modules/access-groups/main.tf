module "access_group" {
  count  = var.existing_access_group_name != null ? 1 : 0
  source = "git::https://github.com/terraform-ibm-modules/terraform-ibm-iam-access-group.git/?ref=v1.3.0"
  providers = {
    ibm = ibm
  }
  provision         = false
  access_group_name = var.existing_access_group_name
  add_members       = false
  dynamic_rules     = {}
  policies = {
    watson_assistant_edit = {
      roles = ["Reader", "Writer", "Viewer", "Editor"]
      tags  = []
      resources = [
        {
          service       = "conversation"
          resource      = var.watsonx_assistant_id
          resource_type = "assistant"
      }]
    }
    watson_assistant_environment_edit = {
      roles = ["Reader", "Writer", "Viewer", "Editor"]
      tags  = []
      resources = [{
        service       = "conversation"
        resource      = var.assistant_environment_id
        resource_type = "environment"
      }]
    }
    watson_assistant_search_edit = {
      roles = ["Reader", "Writer", "Viewer", "Editor"]
      tags  = []
      resources = [{
        service       = "conversation"
        resource      = var.assistant_search_skill_id
        resource_type = "skill"
      }]
    }
    watson_assistant_action_edit = {
      roles = ["Reader", "Writer", "Viewer", "Editor"]
      tags  = []
      resources = [{
        service       = "conversation"
        resource      = var.assistant_action_skill_id
        resource_type = "skill"
      }]
    }
  }
}
