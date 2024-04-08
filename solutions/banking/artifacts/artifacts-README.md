
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

The RAG application pattern artifacts include documents uploaded andindexed in Watson Discovery. Content/passages from these documents
is retrieved by the watsonx Assistant custom extension.

APIs are needed to create the Watson Discovery artifacts.

1.	Create Discovery Project
- https://cloud.ibm.com/apidocs/discovery-data#createproject

2.	Create Colleciton in the Project
- https://cloud.ibm.com/apidocs/discovery-data#createcollection

3.	Import trainig model to the Collection
File: WatsonDiscoveryModel.sdumodel
- Details TBD. Currently manual step. Does not appear to have API.

4.	Add/Upload PDF files to the collections
- https://cloud.ibm.com/apidocs/discovery-data#adddocument
- Documents: FAQ-1.pdf...FAQ-7.pdf (7 documents)

5.	Get the URL/Instance ID, Project and Collection ID
- Captured from the steps done before





> Artifacts for watsonx Assistant

The RAG application pattern artifacts include the watsonx Assistant action skill configuration that drives the chat conversations, custom extensions that makes queries to Watson Discovery to retrieve content, to watsonx.ai Prompt Template deployment for inferencing, and web chat interface the enables the chat interface.

APIs are needed to create the watsonx Assistant artifacts. The watsonx APIs can use the Bearer Token of the administrative DA user or the "application owner" user. This user was created earlier and the API key stored in Secrets Manager. Use the API key to get Bearer Token from IAM endpoint. Use the Bearer Token to call the APIs.

1.	Create assistant (workspace/project)
- https://cloud.ibm.com/apidocs/assistant-v2#createassistant
- Assistant name: cc-bank-loan-demo-v1

2. Create/import custom extension for Watson Discovery from the OpenAI json file
- JSON File: watson-discovery-custom-ext-api-query-openapi.json
- Extension name : watson-discovery-custom-ext-v1

3. Create/import custom extension for watsonx.ai from the OpenAI json file
- JSON File: watsonx-custom-ext-api-call.openapi.json
- Extension name: wx-ai-custom-ext-v1

Currently 2 and 3  are manual steps from watsonx Assistant UI. API details TBD.

4. Create/import RAG pattern action skill from the action json file
- https://cloud.ibm.com/apidocs/assistant-v2#importskills
- JSON File: cc-bank-loan-v1-action.json

5. Get assistant environment details, integration id etc. for web chat interface
- https://cloud.ibm.com/apidocs/assistant-v2#getenvironment
