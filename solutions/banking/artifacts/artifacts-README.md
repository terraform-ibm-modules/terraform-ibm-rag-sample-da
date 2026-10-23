
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
