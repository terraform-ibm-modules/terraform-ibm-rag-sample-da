# Elasticsearch Artifacts

This directory contains the artifacts used to configure the IBM Cloud Databases for Elasticsearch instance that backs the RAG (Retrieval-Augmented Generation) application.

## How Elasticsearch fits into the RAG pattern with watsonx Orchestrate

The Elastic index serves as the **vector/keyword knowledge base** for the banking application. When a user sends a query via the watsonx Orchestrate web chat interface, the Orchestrate agent invokes the Watson Discovery / Elasticsearch tool to retrieve relevant passages from the index. These passages are then passed to watsonx.ai for inferencing (answer generation) before the response is returned to the user.

```
User → watsonx Orchestrate agent
             ↓
     Elasticsearch tool/skill  →  Elastic index  (this DA provisions this)
             ↓
     watsonx.ai tool/skill     →  Prompt Template deployment
             ↓
         Response to user
```

The Elastic index and its sample data are provisioned automatically by this DA via the `configure_elastic_index` Terraform module. The watsonx Orchestrate tools that query the index must be configured separately in the Orchestrate UI (see `artifacts-README.md`).

## Files

### `elastic-index-schema.json`

Defines the **field mapping** for the Elasticsearch index. Used directly by Terraform (`configure_elastic_index` module) to create the index with the correct schema.

Fields:
- `url` → mapped to the `source` field (document source / FAQ ID)
- `body` → mapped to the `text` field (passage content)
- `title` → mapped to the `title` field (question / document title)

> **Note:** This file was previously named `elastic-search-skill.json` and contained additional Watson Assistant search skill configuration (Elasticsearch connection details, conversation messages). That content has been removed — the Elasticsearch connection is now supplied entirely at runtime via Terraform's service binding (`elastic_instance_crn` / `elastic_credentials_name`), and the Orchestrate tool configuration replaces the old Assistant search skill.

### `bank-loan-faqs.json`

Contains **sample FAQ data** for the banking application (bank loan questions and answers). Uploaded into the Elasticsearch index by Terraform when `elastic_upload_sample_data = true` (default).

Each entry has three fields matching the schema above:
- `source` — FAQ document identifier (e.g. `FAQ-5`)
- `title` — The question text
- `text` — The answer text

### `bank-loan-faqs.csv`

The same sample FAQ data in CSV format. Not used directly by Terraform. Provided as a convenience for human review or conversion:

```bash
sudo npm install -g csvtojson
csvtojson ./bank-loan-faqs.csv > ./bank-loan-faqs.json
```
