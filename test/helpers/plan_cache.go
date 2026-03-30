// Copyright © 2025, SAS Institute Inc., Cary, NC, USA. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0

package helpers

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"github.com/gruntwork-io/terratest/modules/terraform"
	test_structure "github.com/gruntwork-io/terratest/modules/test-structure"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/require"
)

var lock = &sync.Mutex{}
var CACHE *PlanCache
var credentialsFile string
var credentialsContents map[string]string

type PlanCache struct {
	plans map[string]*terraform.PlanStruct
	lock  sync.Mutex
}

func getCache() *PlanCache {
	if CACHE == nil {
		lock.Lock()
		defer lock.Unlock()
		if CACHE == nil {
			CACHE = &PlanCache{
				plans: make(map[string]*terraform.PlanStruct),
			}
		}
	}
	return CACHE
}

// Not worrying about expiration since this is for a single run of tests.
func (c *PlanCache) get(key string, planFn func() *terraform.PlanStruct) *terraform.PlanStruct {
	c.lock.Lock()
	defer c.lock.Unlock()

	plan, ok := c.plans[key]
	if !ok {
		c.plans[key] = planFn()
		return c.plans[key]
	}
	return plan
}

func GetDefaultPlan(t *testing.T) *terraform.PlanStruct {
	return GetPlanFromCache(t, GetDefaultPlanVars(t))
}

func GetPlanFromCache(t *testing.T, variables map[string]interface{}) *terraform.PlanStruct {
	return getCache().get(variables["prefix"].(string), func() *terraform.PlanStruct {
		return GetPlan(t, variables)
	})
}

func GetPlan(t *testing.T, variables map[string]interface{}) *terraform.PlanStruct {
	plan, err := InitPlanWithVariables(t, variables)
	require.NotNil(t, plan)
	require.NoError(t, err)
	return plan
}

// Validate that the credentials file exists
func GetCredentials(t *testing.T) (string, map[string]string, error) {
	if credentialsFile != "" {
		return credentialsFile, credentialsContents, nil
	}
	credentialsFile = os.Getenv("TF_VAR_service_account_keyfile")
	if credentialsFile == "" {
		t.Log("Environment variable TF_VAR_service_account_keyfile is not set. Defaulting to /.viya4-tf-gcp-service-account.json")
		credentialsFile = "/.viya4-tf-gcp-service-account.json"
	}

	if _, err := os.Stat(credentialsFile); os.IsNotExist(err) {
		t.Fatalf("Credentials file %s does not exist", credentialsFile)
	}

	file, err := os.Open(credentialsFile)
	if err != nil {
		return "", nil, err
	}
	defer file.Close()

	decoder := json.NewDecoder(file)
	err = decoder.Decode(&credentialsContents)
	if err != nil {
		return "", nil, err
	}

	return credentialsFile, credentialsContents, nil
}

// InitPlanWithVariables returns a *terraform.PlanStruct
func InitPlanWithVariables(t *testing.T, variables map[string]interface{}) (*terraform.PlanStruct, error) {
	// Create a temporary plan file
	planFileName := "testplan-" + variables["prefix"].(string) + ".tfplan"
	planFilePath := filepath.Join(os.TempDir(), planFileName)
	defer os.Remove(planFilePath)

	// Copy the terraform folder to a temp folder
	tempTestFolder := test_structure.CopyTerraformFolderToTemp(t, "../../", "")
	// Get the path to the parent folder for clean up
	tempTestFolderSlice := strings.Split(tempTestFolder, string(os.PathSeparator))
	tempTestFolderPath := strings.Join(tempTestFolderSlice[:len(tempTestFolderSlice)-1], string(os.PathSeparator))
	defer os.RemoveAll(tempTestFolderPath)

	// Set up Terraform options
	terraformOptions := &terraform.Options{
		TerraformDir: tempTestFolder,
		Vars:         variables,
		PlanFilePath: planFilePath,
		NoColor:      true,
	}

	return terraform.InitAndPlanAndShowWithStructE(t, terraformOptions)
}

// GetDefaultPlanVars returns a map of default terratest variables
func GetDefaultPlanVars(t *testing.T) map[string]interface{} {
	_, credsFileContents, err := GetCredentials(t)
	if err != nil {
		t.Fatal(err)
	}
	tfVarsPath := "../../examples/sample-input-defaults.tfvars"

	variables := make(map[string]interface{})
	err = terraform.GetAllVariablesFromVarFileE(t, tfVarsPath, &variables)
	assert.NoError(t, err)

	variables["prefix"] = "default"
	variables["location"] = "us-east1-b"
	variables["default_public_access_cidrs"] = []string{"123.45.67.89/16"}
	variables["project"] = credsFileContents["project_id"]
	variables["service_account_keyfile"] = "/.viya4-tf-gcp-service-account.json"
	variables["kubernetes_version"] = "1.34"

	return variables
}
