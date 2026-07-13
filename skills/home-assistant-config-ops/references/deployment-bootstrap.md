# Deployment Metadata Bootstrap

Use `.deployment_info` only for concise, non-secret facts about one Home
Assistant instance. Do not place generic commands in it.

## Interview

Ask first: Is HA on Kubernetes, reachable by SSH, or local? Where is the
configuration, and how is an approved repository revision transferred and
restarted?

Collect only relevant values:

- Kubernetes: namespace, workload kind/name, container, config path, pod
  selector, Git remote/branch, transfer type, and restart strategy.
- SSH: host alias, config path, runtime type (service, container, or Compose),
  Git remote/branch where applicable, transfer type, and restart strategy.
- Local: config path, runtime directory/type, Git remote/branch where
  applicable, transfer type, and reload/restart strategy.

For every method, record the source of truth, backup ownership, any recovery
fallback for manual production changes and its side effects, plus exceptional
operational notes. Never store credentials or secret material.

## Verify before saving

Use method-specific read-only operations to verify every supplied value:

- confirm access, target identity, and actual HA version;
- confirm the config path, Git remote/branch, and worktree status;
- confirm status and logs are readable;
- on Kubernetes, resolve a Running/Ready pod from the selector.

If access or a value differs, report the discrepancy and request correction.
Do not guess, request raw credentials, reload, restart, or save unverified data
unless the user explicitly accepts that limitation.

Copy [deployment_info.template](../assets/deployment_info.template) to the
repository root as `.deployment_info`, remove irrelevant fields, and replace
all placeholders with verified values.
