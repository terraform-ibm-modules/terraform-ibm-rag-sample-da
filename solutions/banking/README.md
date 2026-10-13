Deployable Architecture for Watsonx generative AI customer care application and toolchains - to deploy to Code Engine.

# Inputs affecting behavior

* `watson_discovery_instance_crn` - if provided, a discovery project will be created and sample data from [artifacts/WatsonDiscovery](artifacts/WatsonDiscovery) will be uploaded into a collection. Region and instance GUID are automatically extracted from the CRN.
* `watsonx_machine_learning_instance_crn` - if provided, a COS instance and a project will be created in the referenced WML instance. Region and instance GUID are automatically extracted from the CRN.
* `elastic_instance_crn` - if provided, the following resources will be provisioned:
  * New index in the Elastic DB
  * Sample data from [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.json) uploaded into the index (can be skipped if `elastic_upload_sample_data = false` )

**NOTE**: the [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.csv) sample data is also available in CSV format which can be converted to json using `csvtojson` tool:
```bash
sudo npm install -g csvtojson
csvtojson ./artifacts/watsonx.Assistant/bank-loan-faqs.csv > ./artifacts/watsonx.Assistant/bank-loan-faqs.json
```
