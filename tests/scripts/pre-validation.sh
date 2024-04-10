#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to deploy the RAG DA resources.                                          #
########################################################################################################################

set -e

DA_DIR="solutions/banking"
TERRAFORM_SOURCE_DIR="tests/resources/existing-resources"
JSON_FILE="${DA_DIR}/catalogValidationValues.json"
REGION="us-south"
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
    echo "prefix=\"rag-da-$(openssl rand -hex 2)\""
  } >> ${TF_VARS_FILE}
  terraform apply -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  toolchain_region_var_name="toolchain_region"
  ci_pipeline_id_var_name="ci_pipeline_id"
  cd_pipeline_id_var_name="cd_pipeline_id"
  watson_assistant_instance_id_var_name="watson_assistant_instance_id"
  watson_assistant_region_var_name="watson_assistant_region"
  watson_discovery_instance_id_var_name="watson_discovery_instance_id"
  watson_discovery_region_var_name="watson_discovery_region"

  ci_pipeline_id_value=$(terraform output -state=terraform.tfstate -raw ci_pipeline_id)
  cd_pipeline_id_value=$(terraform output -state=terraform.tfstate -raw cd_pipeline_id)
  watson_assistant_instance_id_value=$(terraform output -state=terraform.tfstate -raw watson_assistant_instance_id)
  watson_discovery_instance_id_value=$(terraform output -state=terraform.tfstate -raw watson_discovery_instance_id)

  echo "Appending required input variable values to ${JSON_FILE}.."

  cd "${cwd}"
  jq -r --arg toolchain_region_var_name "${toolchain_region_var_name}" \
        --arg toolchain_region_value "${REGION}" \
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
        '. + {($toolchain_region_var_name): $toolchain_region_value,
          ($ci_pipeline_id_var_name): $ci_pipeline_id_value,
          ($cd_pipeline_id_var_name): $cd_pipeline_id_value,
          ($watson_assistant_instance_id_var_name): $watson_assistant_instance_id_value,
          ($watson_assistant_region_var_name): $watson_assistant_region_value,
          ($watson_discovery_instance_id_var_name): $watson_discovery_instance_id_value,
          ($watson_discovery_region_var_name): $watson_discovery_region_value}' "${JSON_FILE}" > tmpfile && mv tmpfile "${JSON_FILE}" || exit 1

  echo "Pre-validation complete successfully"
)
