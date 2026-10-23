Deployable Architecture for Watsonx generative AI customer care application and toolchains - to deploy to Code Engine.

# Inputs affecting behavior

* `watson_discovery_instance_crn` - if provided, a discovery project will be created and sample data from [artifacts/WatsonDiscovery](artifacts/WatsonDiscovery) will be uploaded into a collection. Region and instance GUID are automatically extracted from the CRN.
* `watsonx_machine_learning_instance_crn` - if provided, a COS instance and a project will be created in the referenced WML instance. Region and instance GUID are automatically extracted from the CRN.
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

# Upgrading from versions that used the restapi provider

This solution no longer uses the `Mastercard/restapi` provider. API calls are made with the `hashicorp/http` provider and, where an object has to be created and deleted, with curl scripts run by the `scottwinkler/shell` provider (the same pattern the assistant itself already used).

The `http` provider only has a data source. It can read and it can send a `POST`, but it cannot own an object's lifecycle, so the two are split like this:

| Module | Reads and idempotent updates (`data "http"`) | Create, read, update, delete (`shell_script` + curl) |
| --- | --- | --- |
| watson-assistant | environment lookup, search skill update, action skill import, skill references update | assistant (unchanged) |
| watson-discovery | project details | project, collection |
| watson-machine-learning | project details | watsonx.ai project, storage delegation (the watsonx-ai submodules are inlined) |
| roks-ingress | re-pointing the NLB DNS entry to the ingress load balancer | NLB DNS entry, including the domain and TLS secret cleanup on destroy |

Because the `http` data sources are refreshed on every plan and apply, the `POST` calls in the first column run every time. They are idempotent (they set the same values each time), but they do call the APIs during `terraform plan`.

What happens on the first apply after upgrading:

* The old `restapi_object` entries are dropped from state without being deleted.
* The Discovery project and collection, the watsonx.ai project and the storage delegation are adopted by name (or by COS instance GUID), so nothing is re-created.
* The public ingress NLB DNS entry cannot be matched by name, so a new entry with a new subdomain is created and the ingress controller is updated to use it. The old entry stays in the cluster and can be removed with `ibmcloud ks nlb-dns rm`.

Run `terraform plan` and check it before applying.
