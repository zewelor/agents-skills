---
name: github-actions-maintainer
description: Maintain GitHub Actions workflows, permissions, and publishing boundaries. Use when workflow configuration is in scope, including CI failures caused by it.
---

# GitHub Actions Maintainer

Keep workflow behavior explicit, least-privileged, and easy to verify. Prefer a
small trusted pipeline over reusable abstraction that hides events,
permissions, credentials, or publication conditions.

Before editing, inspect affected callers and called workflows far enough to identify
which jobs execute code, receive credentials, or publish. Identify the trust boundary and
publication side effects before changing triggers, privileges or credentials.
Keep publication, release and settings changes within explicit authorization.
When reviewing, diagnosing, or changing a workflow, read the guidance for the topics involved.

- [Event selection, concurrency or reruns](references/events.md)
- [Trust boundaries, permissions or action references](references/trust.md)
- [Image builds, ghcr, buildx cache or releases](references/publishing.md)

## Reliability and Validation

- Add `timeout-minutes` to bound stuck jobs.
- Consider `parallel` for independent steps within one job; execution continues
  after the group finishes. Use `background: true` for asynchronous steps,
  `wait`/`wait-all` to synchronize, and `cancel` to stop background services.
  Check the [workflow syntax documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsparallel)
  before implementation.
- Scope concurrency to the release unit and apply the sequence checks in [Execution Selection](references/events.md) before enabling cancellation or replacing pending runs. Keep reusable
  workflow groups from unintentionally cancelling their callers or unrelated work.
  Group writes by their shared mutable destination: separate branch/tag/manual
  groups can still race on `latest`. Unique run groups prevent replacement but
  allow overlapping writers. Serialization does not guarantee commit-order dispatch;
  state the intended behavior for old-ref reruns and manual publications. Preserve
  unique tag/manual run groups when every request must be retained; changing them
  to a shared group also authorizes pending replacement and needs a policy decision.
- Preserve existing runner labels, including architecture and Ubuntu version,
  unless changing them is in scope. For new jobs, default to `ubuntu-latest` on
  x64; use a native ARM runner when needed. Verify available labels in current
  GitHub documentation and explain a fixed Ubuntu version in an adjacent YAML
  comment.
- Keep shell commands fail-fast and quote variables. Avoid embedding secrets in
  command lines or logs.
- Retry only an operation that is safe to repeat. Bound attempts and elapsed
  time, and propagate failure after exhaustion. Check recovery and permanent
  failure with harmless fixtures; account for wrapper pre/post hooks before
  assuming how many times a command executes.
- Run repository-native validation first. Run `actionlint` and `zizmor` when
  already available; do not install missing tools automatically without user
  approval.
- Parse every changed workflow as YAML and inspect the complete caller/callee
  permission chain.
- For changes to Docker inputs or build/smoke commands, run the relevant
  repository Dockerfile lint and smoke build. For selection-only changes, validate
  event/path decisions and workflow syntax; do not add full application or image
  suites unless repository requirements or an identified risk require them.
  Treat a native smoke build as different from a multi-platform push.
- When acceptance requires hosted Actions evidence, inspect an available run
  matching the relevant revision and event, including the affected step and its
  result. If matching evidence is unavailable, report the missing proof; do not
  trigger a run, publish, or deploy without the necessary authorization.
- Finish with `git diff --check` and a focused diff review. State which behavior
  was validated locally, which was verified in Actions, and which remains
  pending a trusted publish or deployment event. List any remaining repository or
  package settings needed for the workflow to work.
