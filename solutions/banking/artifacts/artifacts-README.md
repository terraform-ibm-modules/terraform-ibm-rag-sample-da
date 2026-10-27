
> Artifacts for watsonx.ai

The RAG application pattern artifacts include Project Template that must be set up in a watsonx Project. It is used for development/testing of Prompts and then deployed to a Deployment space for inferencing and integration with watsonx.governance.

APIs are needed to create the watsonx Project with artifacts and to deploy them. The watsonx APIs must use the Bearer Token of the "application owner" user. This user was created earlier and the API key stored in Secrets Manager. Use the API key to get Bearer Token from IAM endpoint. Use the Bearer Token to call the APIs.
Reference:
https://cloud.ibm.com/docs/account?topic=account-iamtoken_from_apikey

1.	Create user profile in watsonx
- Create profile for the "application owner" user that was created before by the Users and Secrets DA
- https://github.ibm.com/dap/dap-planning/issues/32444#issuecomment-73563335

2.	Create watsonx Project with artifacts
- Associate Object Storage and Machine Learning
- Add the RAG enabler pattern assets - Project Template, data sets etc. to the watsonx Project.
- https://github.ibm.com/dap/dap-planning/issues/32968

3.	Deploy the Project Template to Deployment Space
- Get the private and public endpoints for inferencing deployment
- https://github.ibm.com/dap/dap-planning/issues/32969





> Artifacts for Watson Discovery

The RAG application pattern artifacts include documents uploaded and indexed in Watson Discovery. Content/passages from these documents
is retrieved by the watsonx Orchestrate Watson Discovery tool.

APIs are needed to create the Watson Discovery artifacts.

1.	Create Discovery Project
- https://cloud.ibm.com/apidocs/discovery-data#createproject

2.	Create Collection in the Project
- https://cloud.ibm.com/apidocs/discovery-data#createcollection

3.	Import training model to the Collection
File: WatsonDiscoveryModel.sdumodel
- Details TBD. Currently manual step. Does not appear to have API.

4.	Add/Upload PDF files to the collections
- https://cloud.ibm.com/apidocs/discovery-data#adddocument
- Documents: FAQ-1.pdf...FAQ-7.pdf (7 documents)

5.	Get the URL/Instance ID, Project and Collection ID
- Captured from the steps done before




> Artifacts for watsonx Orchestrate

The RAG application pattern artifacts include the watsonx Orchestrate agent configuration that drives the chat conversations, the tools that query Watson Discovery (or Elasticsearch) to retrieve content and call the watsonx.ai Prompt Template deployment for inferencing, and the web chat interface that enables the end-user chat experience.

APIs are needed to create the watsonx Orchestrate artifacts. The watsonx Orchestrate APIs can use the Bearer Token of the administrative DA user or the "application owner" user. This user was created earlier and the API key stored in Secrets Manager. Use the API key to get a Bearer Token from the IAM endpoint, then use the Bearer Token to call the Orchestrate APIs.
Reference: https://cloud.ibm.com/docs/account?topic=account-iamtoken_from_apikey

Orchestrate imports OpenAPI files directly as tools, so no extensions are needed. Each tool is named after the `operationId` of its endpoint in the OpenAPI file (snake_case is recommended). The OpenAPI files must be OpenAPI 3.0, have exactly one non-parameterized `servers` URL, accept and return JSON, and have an `operationId` and `description` on every endpoint.
Reference: https://developer.watson-orchestrate.ibm.com/tools/create_openapi_tool

1. Add Watson Discovery as a tool
- Configure a Watson Discovery tool that queries the Discovery collection for document retrieval (see "Artifacts for Watson Discovery" above for the URL/Instance ID, Project ID and Collection ID).
- OpenAPI file: watson-discovery-custom-ext-api-query-openapi.json
- Tool name: set through the `operationId` in the file (for example `watson_discovery_query`)
- Import with the Orchestrate CLI: `orchestrate tools import -k openapi -f <openapi-file> [-a <connection-app-id>]`, or with the API `POST /v1/tools`. The optional connection app ID supplies the credentials for the endpoint.
- If Elasticsearch is used as the knowledge base instead of Watson Discovery, configure a retrieval tool for the Elastic index instead (see `Elasticsearch/README.md`).

2. Add watsonx.ai as a tool
- Configure a watsonx.ai tool that calls the Prompt Template deployment for inferencing (see "Artifacts for watsonx.ai" above for the deployment endpoint).
- OpenAPI file: watsonx-custom-ext-api-call.openapi.json
- Tool name: set through the `operationId` in the file (for example `watsonx_ai_generate`)
- Import with the same CLI command or `POST /v1/tools` API as above.

3. Create the agent with the tools
- API: `POST /v1/orchestrate/agents` (https://developer.watson-orchestrate.ibm.com/apis)
- Agent name: cc-bank-loan-demo-v1
- Required fields: `description` and `style`. Set `tools` to the two tools imported above.
- The agent `instructions` drive the RAG conversation: retrieve passages with the Watson Discovery tool, then pass the question and passages to the watsonx.ai tool to generate the answer.

4. Get the details for the web chat interface
- Capture the watsonx Orchestrate instance ID and region for use in the pipeline properties (`watsonx_orchestrate_id`, `watsonx_orchestrate_region`). These are set by this DA from the `watsonx_orchestrate_instance_crn` input.
- Get the agent environment with `GET /v1/orchestrate/agents/{agent_id}/environment` to obtain the `agentId` and `agentEnvironmentId` needed to embed the web chat.
- Embed the web chat with the script generated by `orchestrate channels webchat embed --agent-name=cc-bank-loan-demo-v1`, and configure embedded chat security first.
- Reference: https://developer.watson-orchestrate.ibm.com/webchat/get_started
