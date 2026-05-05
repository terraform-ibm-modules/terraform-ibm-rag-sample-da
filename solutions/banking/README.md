Deployable Architecture for Watsonx generative AI customer care application and toolchains - to deploy to Code Engine.

# CRN-Based Input Architecture

This solution uses **Cloud Resource Name (CRN)** inputs for Watson services, which simplifies configuration and reduces errors:

* **Watson Assistant**: Uses `watson_assistant_instance_crn`
* **Watson Discovery**: Uses `watson_discovery_instance_crn`
* **Watson Machine Learning**: Uses `watson_machine_learning_instance_crn`
* **Secrets Manager**: Uses `secrets_manager_instance_crn`

## Benefits of CRN-Based Inputs

Using CRNs provides several advantages:

1. **Simplified Input Interface**: A single CRN contains all necessary information (region, account ID, instance GUID)
2. **Automatic Extraction**: Region and instance GUID are automatically extracted from the CRN
3. **Reduced Configuration Errors**: Eliminates the risk of mismatched region/GUID pairs
4. **Consistency**: All Watson services now use the same input pattern

## CRN Format

A CRN follows this structure:
```
crn:v1:bluemix:public:service-name:region:account-id:instance-guid::
```

Example:
```
crn:v1:bluemix:public:conversation:us-south:a/1234567890abcdef:abcd1234-5678-90ef-ghij-klmnopqrstuv::
```

## Migration Guide

If you're upgrading from a previous version that used separate ID and region inputs, follow these steps:

### Finding Your CRN

1. **Via IBM Cloud Console**:
   - Navigate to your service instance
   - Click on the instance name
   - Find the CRN in the instance details (usually labeled as "CRN" or "Cloud Resource Name")

2. **Via IBM Cloud CLI**:
   ```bash
   # List all instances of a service
   ibmcloud resource service-instances --service-name <service-name>

   # Get details including CRN
   ibmcloud resource service-instance <instance-name> --output json | jq -r '.crn'
   ```

### Converting Old Variables to CRN Format

| Old Variable Pattern | New Variable | Notes |
|---------------------|--------------|-------|
| `watson_discovery_instance_id` + `watson_discovery_region` | `watson_discovery_instance_crn` | Region is extracted from CRN |
| `watson_machine_learning_instance_guid` + region | `watson_machine_learning_instance_crn` | GUID is extracted from CRN |
| `watson_assistant_instance_id` + region | `watson_assistant_instance_crn` | Region is extracted from CRN |
| `secrets_manager_instance_id` + `secrets_manager_region` | `secrets_manager_instance_crn` | Region is extracted from CRN |

### Example Migration

**Before (old format)**:
```hcl
watson_discovery_instance_id = "12345678-1234-1234-1234-123456789012"
watson_discovery_region       = "us-south"
```

**After (new CRN format)**:
```hcl
watson_discovery_instance_crn = "crn:v1:bluemix:public:discovery:us-south:a/abc123:12345678-1234-1234-1234-123456789012::"
```

# Inputs affecting behavior

* `watson_discovery_instance_crn` - if provided, a discovery project will be created and sample data from [artifacts/WatsonDiscovery](artifacts/WatsonDiscovery) will be uploaded into a collection. Region and instance GUID are automatically extracted from the CRN.
* `watson_machine_learning_instance_crn` - if provided, a COS instance and a project will be created in the referenced WML instance. Region and instance GUID are automatically extracted from the CRN.
* `elastic_instance_crn` - if provided, the following resources will be provisioned:
  * New index in the Elastic DB
  * Sample data from [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.json) uploaded into the index (can be skipped if `elastic_upload_sample_data = false` )
  * Search skill enabled in Watson Assistant workspace pointed to the Elastic index with specified credentials (needs Elastic service credentials `wxasst_db_user`). The credentials (`wxasst_db_user`) are used both to perform Elastic actions from terraform and to be used in the Assistant's Search action.
  * Action skill enabled in Watson Assistant workspace using [predefined action](artifacts/watsonx.Assistant/wxa-conv-srch-es-v1.json).

**NOTE**: the [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.csv) sample data is also available in CSV format which can be converted to json using `csvtojson` tool:
```bash
sudo npm install -g csvtojson
csvtojson ./artifacts/watsonx.Assistant/bank-loan-faqs.csv > ./artifacts/watsonx.Assistant/bank-loan-faqs.json
```
