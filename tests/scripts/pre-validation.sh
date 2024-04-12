#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to deploy the RAG DA resources.                                          #
########################################################################################################################

set -e

DA_DIR="solutions/banking"
TERRAFORM_SOURCE_DIR="tests/resources/existing-resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
PREFIX="rag-da-$(openssl rand -hex 2)"
TF_VARS_FILE="terraform.tfvars"

(
  cwd=$(pwd)
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Provisioning prerequisite RAG DA resources..."
  terraform init || exit 1
  {
    # $VALIDATION_APIKEY is available in the catalog runtime
    echo "ibmcloud_api_key=\"${VALIDATION_APIKEY}\""
    echo "region=\"${REGION}\""
    echo "prefix=\"${PREFIX}\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  prefix_var_name="prefix"
  resource_group_name_var_name="resource_group_name"
  toolchain_region_var_name="toolchain_region"
  toolchain_resource_group_var_name="toolchain_resource_group"
  ci_pipeline_id_var_name="ci_pipeline_id"
  cd_pipeline_id_var_name="cd_pipeline_id"
  watson_assistant_instance_id_var_name="watson_assistant_instance_id"
  watson_assistant_region_var_name="watson_assistant_region"
  watson_discovery_instance_id_var_name="watson_discovery_instance_id"
  watson_discovery_region_var_name="watson_discovery_region"
  watson_machine_learning_instance_crn_var_name="watson_machine_learning_instance_crn"
  watson_machine_learning_instance_guid_var_name="watson_machine_learning_instance_guid"
  watson_machine_learning_instance_resource_name_var_name="watson_machine_learning_instance_resource_name"
  use_existing_resource_group_var_name="use_existing_resource_group_var_name"

  resource_group_name_value=$(terraform output -state=terraform.tfstate -raw resource_group_name)
  toolchain_resource_group_value=$(terraform output -state=terraform.tfstate -raw resource_group_name)
  ci_pipeline_id_value=$(terraform output -state=terraform.tfstate -raw ci_pipeline_id)
  cd_pipeline_id_value=$(terraform output -state=terraform.tfstate -raw cd_pipeline_id)
  watson_assistant_instance_id_value=$(terraform output -state=terraform.tfstate -raw watson_assistant_instance_id)
  watson_discovery_instance_id_value=$(terraform output -state=terraform.tfstate -raw watson_discovery_instance_id)
  watson_machine_learning_instance_crn_value=$(terraform output -state=terraform.tfstate -raw watson_machine_learning_instance_crn)
  watson_machine_learning_instance_guid_value=$(terraform output -state=terraform.tfstate -raw watson_machine_learning_instance_guid)
  watson_machine_learning_instance_resource_name_value=$(terraform output -state=terraform.tfstate -raw watson_machine_learning_instance_resource_name)
  use_existing_resource_group_value=true

  echo "Appending required input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg prefix_var_name "${prefix_var_name}" \
        --arg prefix_value "${PREFIX}" \
        --arg resource_group_name_var_name "${resource_group_name_var_name}" \
        --arg resource_group_name_value "${resource_group_name_value}" \
        --arg toolchain_region_var_name "${toolchain_region_var_name}" \
        --arg toolchain_region_value "${REGION}" \
        --arg toolchain_resource_group_var_name "${toolchain_resource_group_var_name}" \
        --arg toolchain_resource_group_value "${toolchain_resource_group_value}" \
        --arg ci_pipeline_id_var_name "${ci_pipeline_id_var_name}" \
        --arg ci_pipeline_id_value "${ci_pipeline_id_value}" \
        --arg cd_pipeline_id_var_name "${cd_pipeline_id_var_name}" \
        --arg cd_pipeline_id_value "${cd_pipeline_id_value}" \
        --arg watson_assistant_instance_id_var_name "${watson_assistant_instance_id_var_name}" \
        --arg watson_assistant_instance_id_value "${watson_assistant_instance_id_value}" \
        --arg watson_assistant_region_var_name "${watson_assistant_region_var_name}" \
        --arg watson_assistant_region_value "${REGION}" \
        --arg watson_discovery_instance_id_var_name "${watson_discovery_instance_id_var_name}" \
        --arg watson_discovery_instance_id_value "${watson_discovery_instance_id_value}" \
        --arg watson_discovery_region_var_name "${watson_discovery_region_var_name}" \
        --arg watson_discovery_region_value "${REGION}" \
        --arg watson_machine_learning_instance_crn_var_name "${watson_machine_learning_instance_crn_var_name}" \
        --arg watson_machine_learning_instance_crn_value "${watson_machine_learning_instance_crn_value}" \
        --arg watson_machine_learning_instance_guid_var_name "${watson_machine_learning_instance_guid_var_name}" \
        --arg watson_machine_learning_instance_guid_value "${watson_machine_learning_instance_guid_value} "\
        --arg watson_machine_learning_instance_resource_name_var_name "${watson_machine_learning_instance_resource_name_var_name} "\
        --arg watson_machine_learning_instance_resource_name_value "${watson_machine_learning_instance_resource_name_value}" \
        --arg use_existing_resource_group_var_name "${use_existing_resource_group_var_name}" \
        --arg use_existing_resource_group_value "${use_existing_resource_group_value}" \
        '. + {($prefix_var_name): $prefix_value,
          ($resource_group_name_var_name): $resource_group_name_value,
          ($toolchain_region_var_name): $toolchain_region_value,
          ($toolchain_resource_group_var_name): $toolchain_resource_group_value,
          ($ci_pipeline_id_var_name): $ci_pipeline_id_value,
          ($cd_pipeline_id_var_name): $cd_pipeline_id_value,
          ($watson_assistant_instance_id_var_name): $watson_assistant_instance_id_value,
          ($watson_assistant_region_var_name): $watson_assistant_region_value,
          ($watson_discovery_instance_id_var_name): $watson_discovery_instance_id_value,
          ($watson_discovery_region_var_name): $watson_discovery_region_value,
          ($watson_machine_learning_instance_crn_var_name): $watson_machine_learning_instance_crn_value,
          ($watson_machine_learning_instance_guid_var_name): $watson_machine_learning_instance_guid_value,
          ($use_existing_resource_group_var_name): true,
          ($watson_machine_learning_instance_resource_name_var_name): $watson_machine_learning_instance_resource_name_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
