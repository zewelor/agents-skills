---
name: renovate-maintainer
description: Configure, audit, troubleshoot, or simplify Renovate dependency managers, comment annotations, presets, and package rules. Use for Renovate setup, missed dependencies, incorrect version updates, or update-policy changes in new and existing repositories. Skip ordinary dependency upgrades and CI failures unrelated to Renovate configuration.
---

# Renovate Maintainer

Keep dependency detection and update policy explicit with the smallest configuration
that covers the repository. Follow the user's scope and choices over these defaults;
keep audit-only work read-only and reuse authorization already given.

## Inspect the current contract

- Read the configuration, inherited presets, affected version declarations, and
  existing validation commands. Determine the Renovate version when available.
- Keep one repository configuration entry point. For new repositories, prefer
  `.github/renovate.json` unless the user or project conventions select another
  location. Preserve the existing entry point in established repositories unless
  relocation is requested. Renovate uses the first matching filename; check its
  [search order](https://docs.renovatebot.com/configuration-options/#locations-for-configuration-filenames)
  and any runner additions to `configFileNames`.
- Identify built-in and custom managers, datasource and versioning requirements,
  and exceptions such as a stable-channel custom datasource.
- Preserve detected dependencies and effective schedules, automerge, release-age,
  grouping, and update-type policies during refactoring. Change policy only within
  the requested scope.
- Verify uncertain or version-sensitive behavior against official documentation,
  using Context7 when available. Use the [manager catalog](https://docs.renovatebot.com/modules/manager/)
  to check native coverage before adding a custom manager.

## Keep dependency metadata beside the version

- Prefer built-in managers and suitable maintained presets. Avoid duplicate custom
  extraction for dependencies already detected, including supported Docker image references.
- For missed versions, prefer a shared comment-driven regex manager over separate
  managers tied to individual variable names. Share a manager across declarations
  with compatible syntax; keep distinct formats separate when that is clearer.
- Place `# renovate:` metadata immediately above its version declaration. Capture
  `datasource`, `depName` or `packageName`, and `currentValue`; support optional
  `versioning` and `extractVersion` where the dependency requires them. Preserve
  custom datasource configuration and nonstandard version handling.
- Configure matching file paths and the annotation grammar together. Treat comments
  as inputs to that manager, not as automatic Renovate support. Document supported
  field order and quoting; match the adjacent declaration without consuming unrelated values.
- Use RE2-compatible expressions and account for whole-file matching. Verify exact
  capture and template behavior in the [regex manager documentation](https://docs.renovatebot.com/modules/manager/regex/)
  before extending the grammar.

Use an annotation like this for an otherwise undetected Dockerfile argument;
adapt the manager to the actual file format:

```dockerfile
# renovate: datasource=pypi depName=ansible-core
ARG ANSIBLE_VERSION=2.20.0
```

## Keep update policy in package rules

- Keep schedules, automerge, minimum release age, grouping, and allowed update types
  in `packageRules` or an existing shared preset. Keep dependency identity and
  version parsing beside the declaration where the custom manager supports it.
- For projects adopting [shared presets](https://github.com/zewelor/renovate-config),
  use the applicable named presets instead of copying their rules: `github-actions`
  for action automerge and `go` for Go grouping, module minimum bumps and
  `gomodTidy`. Raising the `go.mod` minimum affects module consumers.
  Check the preset documentation. By default, use
  `github>zewelor/renovate-config//presets/<preset>` to follow the preset repository's
  default branch. Pin a verified tag with `#<tag>` only when the project or user
  has a reason to use a specific version; preserve existing pins unless changing
  them is in scope. Unpinned presets can change when that branch changes.
  Add presets after general presets in the existing `extends` list. Remove only
  local rules they replace; preserve project-specific policies and exceptions,
  including any existing policy for reusable workflows or other non-action
  dependencies. Do not activate Renovate without the operator's authorization.
- When creating a Renovate configuration or changing its automerge policy,
  default to automerging GitHub Actions updates, including major versions, after
  CI passes. Preserve the user's scope and explicit project exceptions. Match
  the `github-actions` manager and `action` dependency type to avoid changing
  policies for workflow images and tools. Verify that the automerge mechanism and
  repository protections enforce the intended CI checks; report if unverified.
- Preserve existing GitHub Actions runner labels, including architecture and
  Ubuntu version, unless a runner change is in scope. If workflow changes are
  needed, use `$github-actions-maintainer` when available.
- Combine rules with identical policy using shared match criteria. Preserve rule
  ordering, inherited behavior, and intentional exceptions; compare effective policy,
  not just the number of rules. Check merge behavior in the
  [configuration documentation](https://docs.renovatebot.com/configuration-options/#packagerules).
- When a registry migration is in scope, preserve the version and intended policy,
  verify the new image digest, and update package-name matchers for the new reference.
- For Node.js Docker bases with distribution tags, extend
  [`workarounds:nodeDockerVersioning`](https://docs.renovatebot.com/presets-workarounds/#workaroundsnodedockerversioning)
  to follow LTS schedules with `ignoreUnstable: true`. Add `allowedVersions`
  when the project must stay on a specific LTS major.

## Verify the result

- Run the official config validator with the repository's Renovate version and
  existing validation entry point. Resolve warnings relevant to the change.
- For shared presets, also run an extraction dry-run and inspect the resolved
  configuration and logs: config-validator success alone does not prove remote
  `extends` resolution. Compare effective policy and required CI checks before
  and after migration; distinguish this from an observed hosted bot run.
- For manager changes, run local extraction against a snapshot containing current
  edits. Compare dependency identities, versions, datasource and parsing metadata
  before and after; detect lost or duplicate dependencies.
- Exercise affected version replacements in an isolated fixture, checking that only
  the intended value changes. Include realistic quoting or nonstandard versions
  and unrelated declarations where the changed matcher could misbehave.
- For policy consolidation, compare effective rules for affected packages, update
  types, and exceptions. Keep verification proportional to the change.
- Report commands, results, and remaining gaps. Distinguish config validation,
  extraction, release lookup, update replacement, and hosted bot behavior; do not
  claim later stages from an earlier check. Report unavailable checks as unverified.
