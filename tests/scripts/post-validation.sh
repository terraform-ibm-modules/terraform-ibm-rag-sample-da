#! /bin/bash

########################################################################################################################
## This script is used by the catalog pipeline to destroy the RAG DA resources.                                           ##
########################################################################################################################

set -e

TERRAFORM_SOURCE_DIR="tests/resources/existing-resources"
TF_VARS_FILE="terraform.tfvars"

(
  cd ${TERRAFORM_SOURCE_DIR}
  echo "Destroying prerequisite RAG DA resources..."
  terraform destroy -input=false -auto-approve -var-file=${TF_VARS_FILE} || exit 1

  echo "Post-validation complete successfully"
)
