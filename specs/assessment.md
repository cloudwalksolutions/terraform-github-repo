# Assessment

A review of this module as it stands at `0.1.17` (`main`, `9a4d414`), pulling in
`terraform-google-folder@0.0.26` and `terraform-google-project@0.0.2`.

The findings below came out of using it for real: `platforms-admin` called it to create the
`on-prem` folder, `on-prem-cw-admin-project`, a workspace service account, a state bucket and a WIF
pool in one apply, which succeeded. Everything here is either read out of the source or observed in
the org's live GCP.

## What it gets right

The module is the correct seam and should stay that way. A repository and the GCP space its
Terraform runs against are one concept, and creating them together is why `on-prem-admin` needed no
manual bootstrap: no `gcloud` prep, no service account key, no hand-set Actions variables. The
`GCP_*` variables it writes line up exactly with what `devops-admin`'s `terraform-core.yml`
consumes, so a new admin repo is workspace-ready the moment it exists.

The `0.0.25 → 0.0.26` dependency fix in `terraform-google-folder` was the important one. Before it,
`module.folders` had `depends_on = [module.folder_service_account.email]`, so the folder-admin
service account was created in an admin project that did not exist yet, and a greenfield folder +
project could not apply in one pass. `0.0.26` inverts the edge to folder → projects → service
account. That fix is load-bearing for every new admin repo.

## Defects

Ordered by consequence.

### 1. State buckets are created without versioning

`workspace.tf:20-22` passes `versioning = { first = true }`. The upstream
`terraform-google-modules/cloud-storage` module documents that input as *"map of lowercase
unprefixed name => boolean, defaults to false"* and reads it as
`lookup(var.versioning, lower(each.value), false)`, where `each.value` is the entry in `names` —
here `"${github_repository.repo.name}-tfstate"`. The key `first` never matches, so the lookup falls
through to `false`.

**Verified in the live org — versioning is disabled on every Terraform state bucket:**

```
gs://cws-on-prem-admin-tfstate      versioning = False
gs://cws-platforms-admin-tfstate    versioning = False
gs://cws-org-admin-tfstate          versioning = False
```

This is the most serious item in this document. A state bucket without object versioning has no
recovery path from a truncated write, a bad `terraform state rm`, or an accidental delete — the
prior state generations simply do not exist. `set_admin_roles` grants `storage.admin` to the
workspace SA, so the identity most likely to corrupt state is also the one able to delete objects.

**Fix:** key the map by the actual bucket name.

```hcl
  versioning = {
    "${github_repository.repo.name}-tfstate" = true
  }
```

Then re-apply every admin repo, or enable versioning out of band on the existing buckets — the
fix only affects buckets created afterwards.

### 2. `gcp_folder_name` silently produces a mismatched project

`folder.tf:8` falls back to `var.name` when `gcp_folder_name` is empty. But the project ID is built
downstream by `terraform-google-project` as `<folder_name>-<project_label>-project`, while this
module's own `local.admin_project_id` (`locals.tf:13`) is built from `local.name_prefix` — the repo
name minus its last segment.

For `name = "on-prem-admin"` with `gcp_folder_name` unset: the real project becomes
`on-prem-admin-cw-admin-project`, while `local.admin_project_id` — and therefore
`data.google_project.project`, the state bucket's `project_id`, the WIF pool's `project`, and the
`GCP_PROJECT_ID` Actions variable — all point at `on-prem-cw-admin-project`, which does not exist.
The apply fails partway, having already created the folder and the wrong project.

Nothing in the module signals this. It is a required input dressed as an optional one.

**Fix:** derive both names from one expression, or `validate` that `gcp_folder_name` is non-empty
when `create_gcp_folder && allow_tf_workspaces`.

### 3. `workspace_project_id` is honoured inconsistently

`locals.tf:15` lets a caller override which project holds the workspace, and the service account,
bucket, WIF pool and `data.google_project` all correctly use `local.workspace_project_id`. Three
places do not:

- `folder.tf:30` — `admin_project_iam` binds `local.admin_project_id`, so with an override the six
  workspace roles land on the derived project rather than the one actually in use. The SA ends up
  with no rights where it runs, and rights on a project that may not exist.
- `outputs.tf:8` — `admin_project_id` returns the derived local regardless of the override, so the
  output can name a project the module never touched.
- `locals.tf:42` — the pool ID is derived from `name_prefix`, not from the overridden project.

**Fix:** use `local.workspace_project_id` in all three, and have the output reflect what was
created.

### 4. `create_gcp_folder = false` with `allow_tf_workspaces = true` grants nothing

Both IAM modules are gated on `create_gcp_folder` (`folder.tf:24`, `folder.tf:61`). Turning
workspaces on for an *existing* project therefore produces a service account, a bucket, a WIF pool
and a full set of Actions variables — and no IAM whatsoever. The repo looks provisioned and its
first pipeline run fails on permissions. `github_actions_variable.gcp_folder_id` is skipped too, so
`terraform-core.yml:53` exports an empty `TF_VAR_gcp_folder_id`.

**Fix:** gate `admin_project_iam` on `allow_tf_workspaces` alone; it targets a project, not a
folder, and needs no folder to exist.

### 5. The admin project's API list cannot be extended

`local.admin_project_apis` (`locals.tf:17-23`) is a hardcoded local, and `gcp_projects_to_create`
cannot reach it: `locals.tf:34-38` merges `workspace_projects_to_create` *after* the caller's map,
and both use the key `local.admin_project_label`, so a caller passing `{ "cw-admin" = [...] }` has
it silently discarded.

The five APIs are the right floor, but they are not a ceiling. `platforms-admin` needed
`secretmanager`, `iamcredentials` and `sts` on its platform project and had to declare
`google_project_service` resources in the calling repo, which means that repo now needs a `google`
provider purely to work around the module.

**Fix:** add an `admin_project_extra_apis` input and `concat` it, or make `admin_project_apis` a
variable with the current list as its default. Non-colliding keys in `gcp_projects_to_create`
already work and should be documented as the way to get additional projects.

### 6. `gcp_sa_prefix` produces a broken configuration

`locals.tf:48` builds `full_sa_name` with the prefix and `locals.tf:50-51` build `sa_email` /
`sa_emails` from it, but `iam.tf:61` creates the account with the **unprefixed** `local.sa_name`.
Set the prefix and the module creates `<name>-ws` while the bucket admin binding, the workload
identity binding (`iam.tf:74`) and the `GCP_SERVICE_ACCOUNT` variable all reference
`<prefix>-<name>-ws`, which does not exist.

**Fix:** use `local.full_sa_name` at `iam.tf:61`, or delete the input. Nothing in the org sets it.

### 7. Disabling the pool but not the provider crashes the plan

`iam.tf:32` indexes `google_iam_workload_identity_pool.github_pool[0]` unconditionally, while
`create_workload_identity_pool` and `create_workload_identity_pool_provider` are independent inputs
defaulting to `true`. Setting only the first to `false` fails with an index-out-of-range error.

**Fix:** gate the provider on both flags, or collapse the two inputs into one.

### 8. Cross-repo state access is dropped for multi-lifecycle repos

`folder.tf:85` — `for_each = length(local.sa_emails) == 1 ? toset(var.tfstate_buckets) : toset([])`.
Any repo with `extra_lifecycles` set gets no `objectViewer` grant at all, so a caller passing
`tfstate_buckets` silently receives nothing. `folder.tf:89` also uses the singular `local.sa_email`
rather than iterating.

**Fix:** iterate the `sa_emails` × `tfstate_buckets` product.

### 9. Collaborators and teams are authoritative

`github_repository_collaborators` (`main.tf:51`) has no `count`, and both `teams` and
`collaborators` default to `[]`. The resource is authoritative, so adopting `0.1.10+` on a repo
that has direct collaborators or team grants removes them on the next apply.

This was safe for `platforms-admin` only because `on-prem-admin` and `gke-admin` had no *direct*
collaborators — their access comes from org membership. It will not be safe everywhere.

**Fix:** document it in the upgrade notes; consider `count` on whether either list is non-empty,
accepting that this then cannot remove the last collaborator.

### 10. Smaller items

| Item | Where | Note |
|---|---|---|
| `gcp_project_id` is dead | `variables.tf` | Declared, never referenced. Callers set it believing it does something. |
| Outputs are too thin | `outputs.tf` | Only `name` and `admin_project_id`. No SA email, folder ID, bucket name or WIF provider, so callers re-derive strings the module already knows — which is how naming drift starts. |
| `deletion_policy` is unreachable | `tgp/variables.tf:86` | Defaults to `DELETE` and `terraform-google-folder` does not forward it, so every project the module creates can be destroyed. An admin project holding secrets should be able to opt into `PREVENT`. |
| Upstream modules unpinned | `tgf/main.tf:3`, `tgf/iam.tf:5,16,37`, `tgp/main.tf:22` | No `version =`, so `init -upgrade` can resolve differently over time. This module pins its own two (`~> 8.1`); the children should too. |
| Duplicate folder IAM | `folder.tf:60` vs `tgf/iam.tf` | Both write the same roles for the same member to the same folder. Harmless — `mode` defaults to `additive` — but redundant and confusing. |
| `project_services` gets a qualified ID | `tgp/main.tf:25` | `project_id = google_project.gcp_project.id` passes `projects/<id>`; the module's own output does `split("/", ...)[1]`, so it knows. Works today, fragile. |
| Test is dead | `module_test.go:74` | Reads output `repo_name`, which does not exist (`outputs.tf` has `name`), and passes `github_pages` as a map where the variable is `list(object)`. It cannot pass, and covers no GCP behaviour. |
| README is the empty template | `README.md` | Every section is a blank heading. `CLAUDE.md` was deleted at `0.0.85` and its last version described a `gcp.tf` that no longer exists. |
| No `google` provider constraint | `provider.tf` | Declares only `github`, yet the module creates `google_*` resources and pulls `google-beta` and `random` transitively. Callers get whatever the root resolves. |

## Priorities

1. **Fix the versioning key.** One line, and it is the only finding with unrecoverable
   consequences. Then enable versioning on the three existing state buckets.
2. **Fix `gcp_folder_name`** — guard or derive. It is the failure a new caller is most likely to
   hit, and it half-applies before failing.
3. **Make the admin project's APIs extensible**, so callers stop reaching around the module.
4. Then 3, 4, 6, 7, 8 as ordinary cleanup, and publish real outputs.

## Adjacent

Two bugs in `devops-admin/.github/workflows/terraform-core.yml` shape how this module is
experienced, and are worth fixing alongside:

- **Every `pull_request` run fails.** `Comment Terraform Plan on PR` reads
  `${{ inputs.workspace-dir }}/plan_output.txt`, which the plan step never writes — it runs
  `terraform show -no-color tfplan` to stdout. The plan is readable in the log, but the check is
  always red, which trains people to ignore a red PR check on Terraform repos.
- **`workflow_dispatch` plans but never applies.** The apply condition includes
  `github.event_name == 'workflow_call'`, but inside a reusable workflow `github.event_name` is the
  *caller's* event, so that arm never fires.

## Evidence that a partial apply is the real operational risk

`apps-admin` has been failing at *Terraform Apply* since 2026-03-16 and has never been retried.
That run tried to create four folders and sixteen projects at once; four projects were created,
none of them admin projects, and the run aborted. The GitHub side shows exactly how far it got —
`cgs-admin` has `GCP_FOLDER_ID`, `GCP_PROJECT_ID` and the `*_GCP_SERVICE_ACCOUNT` variables (all
pure string interpolation, set regardless of what exists) but lacks `GCP_PROJECT_NUMBER` and
`GCP_WORKLOAD_IDENTITY_POOL`, both of which depend on `data.google_project` actually reading a
project. Four apps have been stuck for six months.

That split is a useful diagnostic and argues for two module changes: the string-only variables
should not be written when the resources they describe were not created, and callers should be
steered toward adding one repo at a time rather than a batch.
