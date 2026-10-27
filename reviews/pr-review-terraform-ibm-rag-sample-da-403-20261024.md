# Terraform PR Review

## PR Metadata
- **PR**: [#403 — Remove watsonx Assistant, replace with watsonx Orchestrate](https://github.com/terraform-ibm-modules/terraform-ibm-rag-sample-da/pull/403)
- **Branch**: `issue_20695`
- **Changed Files**: 30 | **Additions**: ~+52 | **Deletions**: ~-4750

---

## Summary
| Severity | Count |
|----------|-------|
| 🔴 Critical | 0 |
| ⚠️ High | 4 |
| 🟡 Medium | 5 |
| ℹ️ Low | 2 |

---

## ⚠️ High Priority Issues

### H1 — `provider_visibility` defaults to `public` instead of `private`
**File**: `solutions/banking/variables.tf` (line 10)
**Category**: DA Compliance — Provider Visibility Default

**Current Code**:
```hcl
# Defaulting this to public to workaround https://github.com/IBM-Cloud/terraform-provider-ibm/issues/5828
default = "public"
```

**Issue**: DA guidelines require `provider_visibility` to default to `"private"`. This has been intentionally set to `"public"` with a workaround comment referencing a provider bug. The referenced issue should be confirmed as still open — if it has been fixed in `IBM-Cloud/ibm v2.6.1` (the locked provider version), this default must be reverted to `"private"`. Shipping a DA that defaults to public endpoints is a security exposure for catalog users.

**Recommendation**: Confirm whether the linked issue is resolved in `v2.6.1`. If resolved, change the default to `"private"`. If still open, add a comment with a target version by which it will be fixed and track it as a known issue.

---

### H2 — `time` provider version is a range, not exact
**File**: `solutions/banking/version.tf` (line 34)
**Category**: DA Compliance — Provider Version Locking

**Current Code**:
```hcl
time = {
  source  = "hashicorp/time"
  version = ">= 0.14.2"
}
```

**Issue**: All other providers in this file are pinned to exact versions (e.g. `"2.6.1"`, `"3.3.2"`). DA guidelines require all providers to be locked to exact versions so that Renovate automation controls upgrades in a predictable way. A range like `>= 0.14.2` breaks this contract.

**Recommendation**:
```hcl
time = {
  source  = "hashicorp/time"
  version = "0.14.2"
}
```

---

### H3 — Upgrade test permanently skipped with a TODO comment
**File**: `tests/pr_test.go` (lines 221–222)
**Category**: DA Compliance — Test Coverage

**Current Code**:
```go
// TODO: remove this skip once the watsonx_assistant_instance_crn removal is merged into main
t.Skip("Skipping upgrade test due to breaking change: watsonx_assistant_instance_crn was removed and is required on the base branch")
```

**Issue**: Skipping the upgrade test is acceptable as a temporary workaround while `main` still carries the old `watsonx_assistant_instance_crn` variable. However, the TODO must be actioned — once this PR merges to `main`, the `t.Skip` line must be removed in the same release or a follow-up immediately after. The skip should not ship as a permanent state.

**Recommendation**: Create a follow-up issue to re-enable the upgrade test after merge. Replace the `t.Skip` with a link to that issue in the comment so it is trackable:
```go
// TODO(#<issue>): re-enable once this PR is merged to main
```

---

### H4 — `watsonx_orchestrate_instance_crn` not added to `pr_test.go` test vars
**File**: `tests/pr_test.go`
**Category**: DA Compliance — Test Coverage (Issue 32)

**Issue**: The PR adds a new optional variable `watsonx_orchestrate_instance_crn` and new pipeline property resources conditioned on it, but `setupOptions` in `pr_test.go` does not pass this variable, and `tests/resources/existing-resources/main.tf` does not provision a watsonx Orchestrate instance for test use. The new Orchestrate pipeline properties (`watsonx_orchestrate_id`, `watsonx_orchestrate_region`) are never exercised by CI tests.

**Recommendation**: Either:
1. Provision a watsonx Orchestrate instance in `tests/resources/existing-resources/main.tf`, output its CRN, and pass it to `setupOptions` — to fully test the new pipeline properties.
2. Or, if Orchestrate cannot be provisioned in test, add a note in the PR explaining this limitation and track it as a follow-up test issue.

---

## 🟡 Medium Priority Issues

### M1 — `elastic_credentials_name` default is `wxasst_db_user` — stale Watson Assistant reference
**File**: `solutions/banking/variables.tf` (line 195)
**Category**: Code Quality — Stale Reference

**Current Code**:
```hcl
variable "elastic_credentials_name" {
  description = "Name of service credentials used to access Elastic instance"
  type        = string
  default     = "wxasst_db_user"
}
```

**Issue**: The credential name `wxasst_db_user` is a Watson Assistant naming convention (`wxasst` = watsonx Assistant). Now that the DA uses Orchestrate instead of Assistant, this default is misleading. The `existing-resources/main.tf` test still creates this credential under the same name, but the convention should be updated for clarity.

**Recommendation**: Rename the default to something service-agnostic such as `wxo_db_user` or `rag_db_user`, and update the corresponding `service_credential_names` entry in `tests/resources/existing-resources/main.tf`.

---

### M2 — `ibm_catalog.json`: `watsonx_orchestrate_instance_crn` not marked as optional with a description hint
**File**: `ibm_catalog.json` (line 165)
**Category**: DA Compliance — Catalog UX

**Current Entry**:
```json
{
  "key": "watsonx_orchestrate_instance_crn",
  "display_name": "watsonx_orchestrate_instance",
  "custom_config": { ... }
}
```

**Issue**: The variable is optional (`default = null`) but the catalog entry has no `"required": false` field and no description to signal to the catalog user that this is optional and what happens when it is omitted (no Orchestrate pipeline properties will be set). Compare with `watson_discovery_instance_crn` which has the same pattern but also lacks this clarity.

**Recommendation**: Add a description or hint comment in the `ibm_catalog.json` entry, or ensure the variable description in `variables.tf` clearly documents the conditional behavior (it currently does — ensure the catalog inherits it). Consider adding `"required": false` explicitly to be unambiguous.

---

### M3 — `.secrets.baseline` still references old `elastic-search-skill.json` path
**File**: `.secrets.baseline`
**Category**: Housekeeping — Stale Path Reference

**Current Entry (in diff)**:
```json
"solutions/banking/artifacts/Elasticsearch/elastic-search-skill.json": [...]
```

**Issue**: The file `elastic-search-skill.json` was renamed to `elastic-index-schema.json` on this branch. The `.secrets.baseline` still references the old filename. This will cause `detect-secrets` to flag a missing file on next scan.

**Recommendation**: Update `.secrets.baseline` to reflect the renamed file path (`elastic-index-schema.json`) or remove the entry entirely since the new `elastic-index-schema.json` no longer contains any credential placeholders (the `elastic_search` connection block was stripped).

---

### M4 — `solutions/banking/README.md` does not mention watsonx Orchestrate
**File**: `solutions/banking/README.md`
**Category**: Documentation

**Issue**: The README was updated to remove the Watson Assistant references but does not mention watsonx Orchestrate at all. A user reading the README has no indication that Orchestrate is now part of the pattern, what `watsonx_orchestrate_instance_crn` does, or how Orchestrate integrates with the Elastic index.

**Recommendation**: Add a bullet for `watsonx_orchestrate_instance_crn` in the "Inputs affecting behavior" section, e.g.:
```
* `watsonx_orchestrate_instance_crn` - if provided, the Orchestrate instance ID and region
  are set as pipeline properties (`watsonx_orchestrate_id`, `watsonx_orchestrate_region`),
  enabling the deployed app to connect to the Orchestrate agent.
```

---

### M5 — URL format in `output "watsonx_orchestrate_api_url"` may be incorrect
**File**: `solutions/banking/outputs.tf` (line 13)
**Category**: Correctness

**Current Code**:
```hcl
value = var.watsonx_orchestrate_instance_crn != null ? "https://api.${local.watsonx_orchestrate_instance_region}.watsonx-orchestrate.assistant.watson.cloud.ibm.com/instances/${local.watsonx_orchestrate_instance_guid}" : null
```

**Issue**: The watsonx Orchestrate API base URL format should be verified against the official IBM Cloud API reference. The old Assistant URL used `api.<region>.assistant.watson.cloud.ibm.com`. The Orchestrate equivalent may differ — the `watsonx-orchestrate` subdomain in the hostname has not been confirmed against published documentation.

**Recommendation**: Verify this URL format against `https://cloud.ibm.com/apidocs/watsonx-orchestrate` before merge. If the correct format differs, update accordingly.

---

## ℹ️ Low Priority Suggestions

### L1 — `removed {}` block `from` path still references the old module — correct, but worth a note
**File**: `solutions/banking/main.tf` (line 317)

The `removed { from = module.configure_watson_assistant }` block is correct Terraform practice for state tombstoning. No code change needed, but the PR description should call this out explicitly so reviewers understand why the module reference appears in code even though it is deleted.

---

### L2 — `solutions/banking/artifacts/watsonx.Assistant/` directory artifacts deleted without a `removed`-style note in artifacts-README
**File**: `solutions/banking/artifacts/artifacts-README.md`

The files `cc-bank-loan-v1-action.json` and `wxa-conv-srch-es-v1.json` were deleted. The updated `artifacts-README.md` (with the new Orchestrate section) mentions equivalent JSON files (`cc-bank-loan-v1-action.json`, `watson-discovery-custom-ext-api-query-openapi.json`, `watsonx-custom-ext-api-call.openapi.json`) that **do not yet exist** in the repository. These are referenced as "JSON File: ..." in the README but are absent from the `artifacts/` directory. This should be noted as a follow-up or the references should be marked as TBD.

---

## DA Compliance Analysis

### `ibm_catalog.json`
| Check | Status | Notes |
|-------|--------|-------|
| No `default_value` on hidden fields | ✅ | Not present |
| `Offerings → Name` matches `ibm_catalog.json` | ✅ | `customer-care-gen-ai-app-config-da` consistent |
| Resource group picker configured | ✅ | `toolchain_resource_group` uses `resource_group` type |
| New `watsonx_orchestrate_instance_crn` entry added | ✅ | Added with `platform_resource` picker |

### Terraform DA Code
| Check | Status | Notes |
|-------|--------|-------|
| Provider versions locked (exact) | ⚠️ | `time` uses `>= 0.14.2` range — see H2 |
| `provider_visibility` defaults to `private` | ⚠️ | Defaults to `public` with workaround comment — see H1 |
| `kms_endpoint_type` independent of `provider_visibility` | ✅ | Not coupled |
| IAM policies: `depends_on` present | ✅ | No IAM policies in DA layer |
| No `protocol = null` in SG rules | ✅ | No SG rules in DA layer |
| Validators have `nullable = false` | 🟡 | New `watsonx_orchestrate_instance_crn` lacks `nullable = false` |
| `removed {}` block for deleted module | ✅ | Correctly present for `module.configure_watson_assistant` |

### Tests
| Check | Status | Notes |
|-------|--------|-------|
| Standard test present | ✅ | `TestRunBankingSolutions` present |
| Upgrade test present | ⚠️ | `TestRunUpgradeExample` is skipped — see H3 |
| New `watsonx_orchestrate_instance_crn` tested | ⚠️ | Not passed in test vars — see H4 |
| Provider visibility set to `public` in tests | ✅ | Set in `setupOptions` |

---

## Semantic Versioning Analysis

### Selected Release Type
**PR Indicates**: Not explicitly stated — based on changes, this is a **breaking change**.

### Recommended Release Type
**Recommendation**: 🔴 **MAJOR**
**Confidence**: High

### Breaking Changes
| Change | Breaking? | Reason |
|--------|-----------|--------|
| `watsonx_assistant_instance_crn` variable removed | ✅ Yes | Required variable (no default) removed — existing deployments referencing it will break |
| `output "watsonx_assistant_api_url"` removed | ✅ Yes | Output removed — downstream consumers break |
| `output "watsonx_assistant_integration_id"` removed | ✅ Yes | Output removed |
| `output "watsonx_assistant_environment"` removed | ✅ Yes | Output removed |
| `output "watsonx_assistant_skills_status"` removed | ✅ Yes | Output removed |
| `module.configure_watson_assistant` removed | ✅ Yes | Module removed — `removed {}` block handles state but API still breaking |
| Pipeline properties `watsonx_assistant_id`, `watsonx_assistant_region`, `watsonx_assistant_integration_id` removed | ✅ Yes | CI/CD pipeline env vars removed — deployed app breaks at runtime |

### Feature Additions
| Feature | Added | Backward Compatible |
|---------|-------|---------------------|
| `watsonx_orchestrate_instance_crn` variable | ✅ | ✅ Optional, default null |
| Orchestrate pipeline properties (id, region) | ✅ | ✅ Count-gated |
| `watsonx_orchestrate_api_url`, `watsonx_orchestrate_id`, `watsonx_orchestrate_region` outputs | ✅ | ✅ New outputs |

### Verdict
⚠️ **VERIFY RELEASE TYPE** — This PR contains multiple **breaking changes** (variable removal, output removals, pipeline property removals). It must be released as a **MAJOR** version bump. Ensure `docs/migration_guide.md` is present or created before merge.

---

## Positive Observations ✅

- The `removed { from = module.configure_watson_assistant; lifecycle { destroy = false } }` block is exactly correct — prevents accidental destruction of existing Assistant resources on upgrade.
- `elastic-search-skill.json` → `elastic-index-schema.json` rename is a good cleanup: strips the dead Assistant connection block and clarifies the file's actual purpose.
- Adding `sensitive = true` and `nullable = false` to `elastic_service_binding` in `modules/elastic-index/variables.tf` is a security improvement.
- The `--connect-timeout` and `--max-time` flags added to all `curl` calls in `elastic-index-utils.sh` are a good reliability improvement.
- Fixing `--header "Accepts:"` → `--header "Accept:"` in the shell scripts is a correct HTTP header fix.
- The `delete_index_entries` logic fix (flipped `!= "index_not_found_exception"` → `== "index_not_found_exception"`) corrects a bug in the original delete-by-query guard.
- `modules/elastic-index/main.tf`: adding `read = "echo {}"` to the `shell_script` lifecycle is correct — avoids unnecessary drift detection on immutable sample data.
- `go.mod` dependency updates (`klauspost/compress`, `golang.org/x/net`) are appropriate patch-level bumps.

---

## Must Fix Before Merge
1. **H1** — Confirm / fix `provider_visibility` default
2. **H2** — Pin `time` provider to exact version
3. **H3** — Add tracking issue for the skipped upgrade test
4. **M3** — Update `.secrets.baseline` to reflect `elastic-index-schema.json` rename
5. **Semver** — Confirm MAJOR release bump and add `docs/migration_guide.md`

## Should Fix Soon
1. **H4** — Add Orchestrate instance to test resources or document the gap
2. **M1** — Rename `wxasst_db_user` default credential name
3. **M4** — Update `solutions/banking/README.md` to mention Orchestrate
4. **M5** — Verify `watsonx_orchestrate_api_url` hostname format against official docs
5. **L2** — Note missing artifact JSON files referenced in `artifacts-README.md` as TBD
