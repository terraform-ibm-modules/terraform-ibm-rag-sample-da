// Tests in this file are run in the PR pipeline and the continuous testing pipeline
package test

import (
	"fmt"
	"io/fs"
	"log"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/gruntwork-io/terratest/modules/files"
	"github.com/gruntwork-io/terratest/modules/logger"
	"github.com/gruntwork-io/terratest/modules/random"
	"github.com/gruntwork-io/terratest/modules/terraform"
	"github.com/stretchr/testify/require"

	"github.com/stretchr/testify/assert"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/cloudinfo"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/common"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testhelper"
	"github.com/terraform-ibm-modules/ibmcloud-terratest-wrapper/testschematic"
)

const bankingSolutionsDir = "solutions/banking"

// const artifactsDir = "solutions/banking/artifacts"
// const watsonScriptsDir = "solutions/banking/watson-scripts"

const region = "us-south" // Binding all the resources to the us-south location.

// Define a struct with fields that match the structure of the YAML data
const yamlLocation = "../common-dev-assets/common-go-assets/common-permanent-resources.yaml"

var permanentResources map[string]interface{}

var sharedInfoSvc *cloudinfo.CloudInfoService

// TestMain will be run before any parallel tests, used to read data from yaml for use with tests
func TestMain(m *testing.M) {
	sharedInfoSvc, _ = cloudinfo.NewCloudInfoServiceFromEnv("TF_VAR_ibmcloud_api_key", cloudinfo.CloudInfoServiceOptions{})

	var err error
	permanentResources, err = common.LoadMapFromYaml(yamlLocation)
	if err != nil {
		log.Fatal(err)
	}

	os.Exit(m.Run())
}

type tarIncludePatterns struct {
	excludeDirs []string

	includeFiletypes []string

	includeDirs []string
}

func getTarIncludePatternsRecursively(dir string, dirsToExclude []string, fileTypesToInclude []string) ([]string, error) {
	r := tarIncludePatterns{dirsToExclude, fileTypesToInclude, nil}
	err := filepath.WalkDir(dir, func(path string, entry fs.DirEntry, err error) error {
		return walk(&r, path, entry, err)
	})
	if err != nil {
		fmt.Println("error")
		return r.includeDirs, err
	}
	return r.includeDirs, nil
}

func walk(r *tarIncludePatterns, s string, d fs.DirEntry, err error) error {
	if err != nil {
		return err
	}
	if d.IsDir() {
		for _, excludeDir := range r.excludeDirs {
			if strings.Contains(s, excludeDir) {
				return nil
			}
		}
		if s == ".." {
			r.includeDirs = append(r.includeDirs, "*.tf")
			return nil
		}
		for _, includeFiletype := range r.includeFiletypes {
			r.includeDirs = append(r.includeDirs, strings.ReplaceAll(s+"/*"+includeFiletype, "../", ""))
		}
	}
	return nil
}

func setupOptionsSchematics(t *testing.T, prefix string, dir string) *testschematic.TestSchematicOptions {

	excludeDirs := []string{
		".terraform",
		".docs",
		".github",
		".git",
		".idea",
		"common-dev-assets",
		"examples",
		"tests",
		"reference-architectures",
	}
	includeFiletypes := []string{
		".tf",
		".yaml",
		".py",
		".tpl",
		".md",
		".json",
		".pdf",
	}

	tarIncludePatterns, recurseErr := getTarIncludePatternsRecursively("..", excludeDirs, includeFiletypes)

	// if error producing tar patterns (very unexpected) fail test immediately
	require.NoError(t, recurseErr, "Schematic Test had unexpected error traversing directory tree")

	options := testschematic.TestSchematicOptionsDefault(&testschematic.TestSchematicOptions{
		Testing:                t,
		Prefix:                 prefix,
		Region:                 region,
		TarIncludePatterns:     tarIncludePatterns,
		TemplateFolder:         dir,
		DeleteWorkspaceOnFail:  false,
		WaitJobCompleteMinutes: 60,
	})
	return options
}

func TestRunBankingSolutions(t *testing.T) {
	t.Parallel()

	// ------------------------------------------------------------------------------------
	// Provision a resource group, watson assistance and watson discovery instances.
	// ------------------------------------------------------------------------------------
	prefix := fmt.Sprintf("rag-da-%s", strings.ToLower(random.UniqueId()))
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy RAG DA passing in existing watson assistance ID and watson discovery ID.
		// ------------------------------------------------------------------------------------
		options := setupOptionsSchematics(t, prefix, bankingSolutionsDir)

		options.TerraformVars = []testschematic.TestSchematicTerraformVar{
			{Name: "elastic_instance_crn", Value: permanentResources["elasticsearch_instance_crn"], DataType: "string"},
			{Name: "toolchain_region", Value: options.Region, DataType: "string"},
			{Name: "prefix", Value: options.Prefix, DataType: "string"},
			{Name: "ci_pipeline_id", Value: terraform.Output(t, existingTerraformOptions, "ci_pipeline_id"), DataType: "string"},
			{Name: "cd_pipeline_id", Value: terraform.Output(t, existingTerraformOptions, "cd_pipeline_id"), DataType: "string"},
			{Name: "watson_assistant_instance_id", Value: terraform.Output(t, existingTerraformOptions, "watson_assistant_instance_id"), DataType: "string"},
			{Name: "watson_assistant_region", Value: terraform.Output(t, existingTerraformOptions, "watson_assistant_region"), DataType: "string"},
			{Name: "watson_discovery_instance_id", Value: terraform.Output(t, existingTerraformOptions, "watson_discovery_instance_id"), DataType: "string"},
			{Name: "watson_discovery_region", Value: terraform.Output(t, existingTerraformOptions, "watson_discovery_region"), DataType: "string"},
			{Name: "use_existing_resource_group", Value: true, DataType: "bool"},
			{Name: "create_continuous_delivery_service_instance", Value: false, DataType: "bool"},
			{Name: "resource_group_name", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
			{Name: "toolchain_resource_group", Value: terraform.Output(t, existingTerraformOptions, "resource_group_name"), DataType: "string"},
			{Name: "watson_machine_learning_instance_crn", Value: terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_crn"), DataType: "string"},
			{Name: "watson_machine_learning_instance_guid", Value: terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_guid"), DataType: "string"},
			{Name: "watson_machine_learning_instance_resource_name", Value: terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_resource_name"), DataType: "string"},
			{Name: "secrets_manager_guid", Value: permanentResources["secrets_manager_guid"], DataType: "string"},
			{Name: "secrets_manager_region", Value: options.Region, DataType: "string"},
			{Name: "signing_key", Value: terraform.Output(t, existingTerraformOptions, "signing_key"), DataType: "string"},
			{Name: "trigger_ci_pipeline_run", Value: false, DataType: "bool"},
			{Name: "create_secrets", Value: false, DataType: "bool"},
		}

		err := options.RunSchematicTest()
		assert.Nil(t, err, "This should not have errored")
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
	realTerraformDir := "./resources/existing-resources"
	tempTerraformDir, _ := files.CopyTerraformFolderToTemp(realTerraformDir, fmt.Sprintf(prefix+"-%s", strings.ToLower(random.UniqueId())))

	// Verify ibmcloud_api_key variable is set
	checkVariable := "TF_VAR_ibmcloud_api_key"
	val, present := os.LookupEnv(checkVariable)
	require.True(t, present, checkVariable+" environment variable not set")
	require.NotEqual(t, "", val, checkVariable+" environment variable is empty")

	logger.Log(t, "Tempdir: ", tempTerraformDir)
	existingTerraformOptions := terraform.WithDefaultRetryableErrors(t, &terraform.Options{
		TerraformDir: tempTerraformDir,
		Vars: map[string]interface{}{
			"prefix": prefix,
			"region": region,
		},
		// Set Upgrade to true to ensure latest version of providers and modules are used by terratest.
		// This is the same as setting the -upgrade=true flag with terraform.
		Upgrade: true,
	})

	terraform.WorkspaceSelectOrNew(t, existingTerraformOptions, prefix)
	_, existErr := terraform.InitAndApplyE(t, existingTerraformOptions)
	if existErr != nil {
		assert.True(t, existErr == nil, "Init and Apply of temp existing resource failed")
	} else {
		// ------------------------------------------------------------------------------------
		// Deploy RAG DA passing in existing watson assistance ID and watson discovery ID.
		// ------------------------------------------------------------------------------------
		options := testhelper.TestOptionsDefault(&testhelper.TestOptions{
			Testing:      t,
			TerraformDir: bankingSolutionsDir,
			// Do not hard fail the test if the implicit destroy steps fail to allow a full destroy of resource to occur
			ImplicitRequired: false,
			Region:           region,
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
				"watson_machine_learning_instance_guid":          terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_guid"),
				"watson_machine_learning_instance_resource_name": terraform.Output(t, existingTerraformOptions, "watson_machine_learning_instance_resource_name"),
				"secrets_manager_guid":                           permanentResources["secretsManagerGuid"],
				"secrets_manager_region":                         region,
				"signing_key":                                    terraform.Output(t, existingTerraformOptions, "signing_key"),
				"trigger_ci_pipeline_run":                        false,
				"secrets_manager_endpoint_type":                  "public",
				"provider_visibility":                            "public",
				"create_secrets":                                 false,
			},
		})

		options.IgnoreDestroys = testhelper.Exemptions{
			List: []string{
				"module.configure_discovery_project[0].null_resource.discovery_file_upload",
			},
		}

		options.IgnoreUpdates = testhelper.Exemptions{
			List: []string{
				"ibm_cd_tekton_pipeline_property.watsonx_assistant_integration_id_pipeline_property_cd",
				"ibm_cd_tekton_pipeline_property.watsonx_assistant_integration_id_pipeline_property_ci",
			},
		}

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
