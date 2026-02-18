// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"bytes"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/IBM/go-sdk-core/v5/core"
	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
)

const bankingSolutionsDir = "solutions/banking"

// watsonx.ai supported regions
var validRegions = []string{
	// Commented `au-syd` region as failure in seen in storage delegation.
	// For more details, see issue: https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da/issues/345
	// "au-syd",
	"jp-tok",
	"eu-gb",
	"eu-de",
	"us-south",
}

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

var sharedInfoSvc *cloudinfo.CloudInfoService

func validateEnvVariable(t *testing.T, varName string) string {
	val, present := os.LookupEnv(varName)
	require.True(t, present, "%s environment variable not set", varName)
	require.NotEqual(t, "", val, "%s environment variable is empty", varName)
	return val
}

func createContainersApikey(t *testing.T, region string, rg string) {

	err := os.Setenv("IBMCLOUD_API_KEY", validateEnvVariable(t, "TF_VAR_ibmcloud_api_key"))
	require.NoError(t, err, "Failed to set IBMCLOUD_API_KEY environment variable")
	scriptPath := "../common-dev-assets/scripts/iks-api-key-reset/reset_iks_api_key.sh"
	cmd := exec.Command("bash", scriptPath, region, rg)
	var stdout, stderr bytes.Buffer
	cmd.Stdout = &stdout
	cmd.Stderr = &stderr

	// Execute the command
	if err := cmd.Run(); err != nil {
		log.Fatalf("Failed to execute script: %v\nStderr: %s", err, stderr.String())
	}
	// Print script output
	fmt.Println(stdout.String())
}

func generateUniqueResourceGroupName(baseName string) string {
	id := uuid.New().String()[:8]
	return fmt.Sprintf("%s-%s", baseName, id)
}

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	var err error
	sharedInfoSvc, err = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})
	if err != nil {
		log.Fatal(err)
	}

	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

func setupOptions(t *testing.T, prefix string, existingTerraformOptions *terraform.Options) *testhelper.TestOptions {

	region := terraform.Output(t, existingTerraformOptions, "region")

	options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
		Testing:            t,
		TerraformDir:       bankingSolutionsDir,
		ApiDataIsSensitive: core.BoolPtr(false),
		// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
		ImplicitRequired:           false,
		Region:                     region,
		CheckApplyResultForUpgrade: true,
		TerraformVars: map[string]interface{}{
			"toolchain_region":                               region,
			"prefix":                                         prefix,
			"ci_pipeline_id":                                 terraform.Output(t, existingTerraformOptions, "ci_pipeline_id"),
			"cd_pipeline_id":                                 terraform.Output(t, existingTerraformOptions, "cd_pipeline_id"),
			"watson_assistant_instance_id":                   terraform.Output(t, existingTerraformOptions, "watson_assistant_instance_id"),
			"watson_assistant_region":                        terraform.Output(t, existingTerraformOptions, "watson_assistant_region"),
			"watson_discovery_instance_id":                   terraform.Output(t, existingTerraformOptions, "watson_discovery_instance_id"),
			"watson_discovery_region":                        terraform.Output(t, existingTerraformOptions, "watson_discovery_region"),
			"use_existing_resource_group":                    true,
			"create_continuous_delivery_service_instance":    false,
			"resource_group_name":                            terraform.Output(t, existingTerraformOptions, "resource_group_name"),
			"toolchain_resource_group":                       terraform.Output(t, existingTerraformOptions, "resource_group_name"),
			"watson_machine_learning_instance_crn":           terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_crn"),
			"watson_machine_learning_instance_resource_name": terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_resource_name"),
			"secrets_manager_guid":                           terraform.Output(t, existingTerraformOptions, "secrets_manager_guid"),
			"secrets_manager_region":                         terraform.Output(t, existingTerraformOptions, "secrets_manager_region"),
			"trigger_ci_pipeline_run":                        false,
			"secrets_manager_endpoint_type":                  "public",
			"provider_visibility":                            "public",
			"elastic_instance_crn":                           terraform.Output(t, existingTerraformOptions, "elasticsearch_crn"),
			"cluster_name":                                   terraform.Output(t, existingTerraformOptions, "cluster_name"),
			"cos_kms_crn":                                    terraform.Output(t, existingTerraformOptions, "kms_instance_crn"),
			"secrets_manager_resource_group_name":            terraform.Output(t, existingTerraformOptions, "resource_group_name"),
		},
		IgnoreUpdates: testhelper.Exemptions{
			List: []string{
				// Need to be checked, see https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da/issues/342
				"module.configure_discovery_project[0].restapi_object.configure_discovery_collection",
				"module.configure_discovery_project[0].restapi_object.configure_discovery_project",
				"module.configure_watson_assistant.restapi_object.assistant_action_skill[0]",
				"module.configure_watson_assistant.restapi_object.assistant_search_skill[0]",
				"module.configure_watson_assistant.restapi_object.assistant_skills_references[0]",
				"module.configure_wml_project[0].restapi_object.configure_project",
				"module.cluster_ingress[0].restapi_object.workload_nlb_dns_cleanup",
				"module.cluster_ingress[0].restapi_object.workload_nlb_dns",
				"module.cluster_ingress[0].restapi_object.workload_nlb_dns_patch",
				"module.configure_wml_project[0].module.storage_delegation[0].restapi_object.storage_delegation",
			},
		},
		IgnoreDestroys: testhelper.Exemptions{
			List: []string{
				// destroy / re-create expected due to always_run trigger
				"module.configure_discovery_project[0].null_resource.discovery_file_upload",
			},
		},
	})

	return options
}

func TestRunBankingSolutions(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision a resource group, watson assistance and watson discovery instances.
	// ------------------------------------------------------------------------------------
	prefix := fmt.Sprintf("rag-da-%s", strings.ToLower(random.UniqueId()))
	region := validRegions[common.CryptoIntn(len(validRegions))]
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")
	logger.Log(t, "Tempdir: ", tempTerraformDir)

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	uniqueResourceGroup := generateUniqueResourceGroupName(prefix)
	rg, _, err := sharedInfoSvc.CreateResourceGroup(uniqueResourceGroup)
	assert.Nil(t, err, "Resource group creation should not have errored")
	assert.NotNil(t, rg, "Expected resource group to be created")
	createContainersApikey(t, region, uniqueResourceGroup)

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":             prefix,
			"region":             region,
			"resource_group":     uniqueResourceGroup,
			"create_ocp_cluster": true,
		},
		// Set Upgrade to true to ensure the latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})
	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)

	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy RAG DA passing in existing cluster, ES, watson assistance ID and watson discovery ID.
		// ------------------------------------------------------------------------------------

		options := setupOptions(t, prefix, existingTerraformOptions)

		output, err := options.RunTestConsistency()
		assert.Nil(t, err, "This should not have errored")
		assert.NotNil(t, output, "Expected some output")
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}

func TestRunUpgradeExample(t *testing.T) {
	t.Parallel()

	prefix := fmt.Sprintf("rag-da-upgr-%s", strings.ToLower(random.UniqueId()))
	region := validRegions[common.CryptoIntn(len(validRegions))]
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")
	logger.Log(t, "Tempdir: ", tempTerraformDir)

	// Temp workaround for https://github.com/terraform-ibm-modules/terraform-ibm-base-ocp-vpc?tab=readme-ov-file#the-specified-api-key-could-not-be-found
	uniqueResourceGroup := generateUniqueResourceGroupName(prefix)
	rg, _, err := sharedInfoSvc.CreateResourceGroup(uniqueResourceGroup)
	assert.Nil(t, err, "Resource group creation should not have errored")
	assert.NotNil(t, rg, "Expected resource group to be created")
	createContainersApikey(t, region, uniqueResourceGroup)

	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix":             prefix,
			"region":             region,
			"resource_group":     uniqueResourceGroup,
			"create_ocp_cluster": true,
		},
		// Set Upgrade to true to ensure the latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)

	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy RAG DA passing in existing cluster, ES, watson assistance ID and watson discovery ID.
		// ------------------------------------------------------------------------------------
		options := setupOptions(t, prefix, existingTerraformOptions)

		output, err := options.RunTestUpgrade()
		if !options.UpgradeTestSkipped {
			assert.Nil(t, err, "This should not have errored")
			assert.NotNil(t, output, "Expected some output")
		}
	}

	// Check if "DO_NOT_DESTROY_ON_FAILURE" is set
	envVal, _ := os.LookupEnv("DO_NOT_DESTROY_ON_FAILURE")
	// Destroy the temporary existing resources if required
	if t.Failed() && strings.ToLower(envVal) == "true" {
		fmt.Println("Terratest failed. Debug the test and delete resources manually.")
	} else {
		logger.Log(t, "START: Destroy (existing resources)")
		terraform.Destroy(t, existingTerraformOptions)
		terraform.WorkspaceDelete(t, existingTerraformOptions, prefix)
		logger.Log(t, "END: Destroy (existing resources)")
	}
}
