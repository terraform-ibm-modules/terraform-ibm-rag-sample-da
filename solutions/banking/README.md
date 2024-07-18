Deployable Architecture for Watsonx generative AI customer care application and toolchains - to deploy to Code Engine.

# Inputs affecting behavior

* `watson_discovery_instance_id` - if provided, a discovery project will be created and sample data from [artifacts/WatsonDiscovery](artifacts/WatsonDiscovery) will be uploaded into a collection
* `watson_machine_learning_instance_guid` - if provided, a COS instance and a project will be created in the referenced WML instance
* `elastic_instance_crn` - if provided, the following resources will be provisioned:
  * New index in the Elastic DB
  * Sample data from [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.json) uploaded into the index (can be skipped if `elastic_upload_sample_data = false` )
  * Search skill enabled in Watson Assistant workspace pointed to the Elastic index with specified credentials (needs Elastic service credentials `toolchain_db_user`)
  * Action skill enabled in Watson Assistant workspace using [predefined action](artifacts/watsonx.Assistant/wxa-conv-srch-es-v1.json). 

**NOTE**: the [bank loan FAQs](artifacts/watsonx.Assistant/bank-loan-faqs.csv) sample data is also available in CSV format which can be converted to json using `csvtojson` tool:
```bash
sudo npm install -g csvtojson
csvtojson ./artifacts/watsonx.Assistant/bank-loan-faqs.csv > ./artifacts/watsonx.Assistant/bank-loan-faqs.json
```
