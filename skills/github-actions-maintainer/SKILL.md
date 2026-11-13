---
name: github-actions-maintainer
description: Maintain GitHub Actions workflows, permissions, and publishing boundaries. Use when workflow configuration is in scope, including CI failures caused by it.
---

# GitHub Actions Maintainer

Keep workflow behavior explicit, least-privileged, and easy to verify. Prefer a
small trusted pipeline over reusable abstraction that hides events,
permissions, credentials, or publication conditions.

## Workflow

1. Read repository instructions and inspect every caller and reusable workflow
   involved in the requested path.
2. Inventory triggers, job dependencies, permissions, secrets, environments,
   third-party actions, caches, artifacts, and publication side effects. Establish
   which changes and events require each job using Execution Selection below.
3. Classify each job as untrusted verification, trusted build, or privileged
   publication/deployment.
4. Assign the smallest permissions and secrets to each job. Split jobs when a
   single permission set would grant write access to verification steps.
5. Review action references, shell interpolation, cache boundaries, concurrency,
   timeouts, and cross-repository access.
6. Validate locally, then inspect real workflow evidence when cache hits,
   registry access, attestations, or publication behavior must be proven.
7. Report remaining operational setup separately from code changes. Preserve
   unrelated work and do not publish, release, or change repository settings
   without explicit authorization.

## Execution Selection

- Start with the repository's release unit and simplest sufficient flow. For one
  application, prefer native workflow triggers, verification jobs, and publication
  gated by `needs`. Publishing the fully verified revision on every qualifying
  main run is a valid simplicity tradeoff; explain that test/config changes may
  publish too. Distinguish latest successful state from every pushed tip or every
  commit within a push; pending replacement cannot satisfy an every-run contract.
  Split workflows for independently released components when their triggers and
  concurrency can be independent. Reuse verification through
  `workflow_call` when useful; moving conditions to another file is not simplification.
- Keep native exclusions for inputs outside the release unit. A skipped workflow
  does not replace a pending run; distinguish that from an admitted run that
  cancels verification or skips publication through a per-push image filter.
  Do not remove all path filters merely because pending replacement is possible.
- Match guarantees to the actual requirement. For a small project accepting
  latest-successful publication and explicit reruns, prefer native `needs` and
  concurrency. Add custom promotion scripts, ancestry checks or registry state
  only for a demonstrated stricter requirement; compare their ongoing cost with
  the accepted race. Do not add application-language tests solely for CI glue.
- Separate eligibility to verify, build an artifact, publish it, and deploy it.
  Successful verification is a prerequisite for publication, not evidence that
  the change requires a new release. Preserve intentional tag, manual, scheduled
  rebuild and per-commit release contracts; state any authorized policy change.
- Derive each artifact's inputs from its actual build: source, dependencies,
  embedded assets, generated inputs, Dockerfile stages, COPY and ignore rules.
  A test database, Compose fixture or CI tool update may require integration
  checks without requiring a production image. Documentation may be embedded;
  do not exclude it by filename alone. Treat independently deployed components
  separately, including their shared inputs.
- Inspect overlapping workflows and `push`/`pull_request` triggers. Prefer one
  verification per intended revision/event; preserve branch-before-PR checks
  when required by the repository or automation. Concurrency keyed by ref does
  not deduplicate a branch push and its PR merge ref.
- Choose the simplest mechanism that preserves these boundaries. Native path
  filters suit whole workflows; job conditions suit differing scopes or required
  checks that must report success. Check required-status behavior before filtering
  a workflow. Prefer existing helpers or documented tooling over custom diff logic.
- When comparing changes, verify the chosen tool's push, PR, initial-branch and
  manual/tag semantics. Cover multi-commit pushes, deletions and renames; unavailable
  comparison data must fail visibly, not silently skip required work. Keep source
  lists aligned with build inputs and avoid weakening tested-artifact guarantees.
- Evaluate selection together with concurrency and release state. A diff against
  the previous push does not include unpublished changes from a cancelled, failed,
  or replaced run. Even `cancel-in-progress: false` can replace a pending run.
  Cancel superseded verification only when its replacement still covers the full
  release unit. Use independent component triggers/concurrency or a verified
  successful-publication baseline when selective publication is required; do not
  add persisted tracking when publishing each qualifying run meets the task.
  Treat an already-started external publication separately: cancellation does not
  roll back side effects. Preserve intentional manual retry/recovery contracts.
- Before editing filters, record representative change/event cases and expected
  jobs: production input, test/fixture-only, docs/tooling-only, mixed changes,
  PR and main push, plus supported release events. Validate both required runs
  and required skips against the resulting configuration. Report local selection
  evidence separately from hosted runs or measured savings. Include sequences:
  runtime then tests-only, component A then B, pending replacement, cancelled or
  failed verification/publication, and rerun. Check which complete revision and
  components are ultimately published, not only each run's isolated predicate.

## Trust and Event Boundaries

- Treat pull-request code, titles, branch names, matrix values, issue content,
  and workflow inputs as untrusted data.
- Prefer `pull_request` for untrusted verification. Do not expose secrets or
  write tokens to forked or Dependabot pull requests.
- Avoid `pull_request_target` with checkout or execution of pull-request code.
  If the event is unavoidable, keep the job metadata-only and never run content
  from the untrusted ref.
- Pass GitHub expressions into shell scripts through quoted environment
  variables instead of interpolating untrusted values directly into `run`.
- Use `permissions: {}` as the workflow default and declare permissions per
  job. Remember that unspecified scopes become `none` once any scope is set.
- Use `secrets: inherit` only when the called workflow genuinely needs every
  available secret; otherwise pass named secrets explicitly.

## Permission Contract

Use this baseline and add scopes only when a step proves the requirement:

| Job purpose | Permissions |
| --- | --- |
| Lint, test, or checkout | `contents: read` |
| Pull private GHCR image | `contents: read`, `packages: read` |
| Publish GHCR image | `contents: read`, `packages: write` |
| Publish build attestation | add `attestations: write`, `id-token: write` |
| Create GitHub Release | `contents: write` |
| Cloud authentication through OIDC | `id-token: write` plus provider-specific minimums |

- Prefer the repository-scoped `GITHUB_TOKEN` over a PAT for GitHub APIs and
  GitHub Packages.
- Grant a consumer repository Read access under the private package's Manage
  Actions access settings; token scope alone does not grant cross-repository
  package access.
- Keep `packages: read` for pulls and `packages: write` only for pushes.
- Grant `id-token: write` only to jobs that actually request OIDC or generate an
  attestation requiring it.
- Treat caller permissions as the ceiling for reusable workflows: nested
  workflows may preserve or reduce permissions, never elevate them.
- Separate verify/build from publish/release when otherwise the test job would
  execute repository code with write permissions.

## Action References

- Check current official documentation before selecting an action or major
  version; do not infer current versions from memory.
- Define or use an explicit trusted-creator allowlist. Prefer major tags such as
  `@v6` for explicitly trusted GitHub-owned or verified actions when automatic
  compatible updates are the chosen house policy.
- Pin other third-party actions to a verified full-length commit SHA and retain
  a version comment when useful for reviewability.
- Never use moving branch references such as `@main` or `@master`.
- Inspect nested action references in composite or wrapper manifests before
  passing secrets or write-scoped tokens. Follow the executable action chain:
  pinning the outer wrapper leaves nested branch/tag references mutable. Pin
  the privileged chain to reviewed SHAs, or use a small native step when the
  wrapper adds unnecessary credential exposure.
- When dependency automation is in scope, use the repository's Renovate or
  Dependabot setup to maintain action references. When configuring
  Renovate automerge, use `$renovate-maintainer` if available. GitHub Actions
  major updates may automerge after CI passes, subject to the user's scope and
  explicit project exceptions. Use an existing shared Actions preset when the
  project adopts one; retain local workflow exceptions and verify required CI
  checks and automerge behavior.
- Set `persist-credentials: false` on checkout unless later steps intentionally
  perform authenticated Git operations.

## Docker, GHCR, and Buildx Cache

Use the Docker skill for Dockerfile stages, build context, image contents,
runtime users, and BuildKit cache mounts. Keep workflow orchestration here.

- Authenticate to a private registry before any build step whose `FROM` may
  pull a private image.
- Build and smoke-test the native runner platform before publishing a
  multi-platform manifest when this gives useful fast feedback.
- For multi-platform builds, inspect which stages execute target-architecture
  binaries. Choose cross-compilation, QEMU, or native runners based on toolchain
  support, compatibility, and comparable build times and cache conditions.
  When publishing separate per-platform images, merge the manifest only after
  the required builds succeed; per-platform digests can identify the inputs.
- Treat successful cross-compilation and a multi-platform manifest as separate
  from runtime verification. Add a native ARM smoke test when ARM runtime support
  warrants ongoing coverage; do not add a matrix solely because cross-compilation
  is supported.
- When configuring Buildx cache, select restore/export behavior and backend from
  the actual producers and consumers; preserve deliberate restore-only jobs:
  - Use `type=gha,scope=${image_name}` for branch and PR workflows where builds run on `main` or feature branches and inherit branch cache without extra registry tags or package write permissions.
  - Consider `type=registry,ref=${registry}/${image}:buildcache` when cross-ref reuse beyond GitHub cache visibility is needed. GitHub cache can restore from the current and default branch, and PRs also from their base branch; different tags cannot restore each other's caches. A manual event alone does not require registry cache, and tag runs may reuse default-branch cache. Verify the required sharing before adding registry writes.
  - Specify the full OCI reference (`ghcr.io/owner/repo:buildcache`) for registry cache and grant the job `packages: write` permissions.
  - Whenever configuring `type=registry` or switching cache backends, add an inline comment directly next to the cache configuration in the workflow file explaining why that backend was chosen (e.g. noting that tag-triggered builds require registry cache to share layers across release tags).
- Use `mode=max` when intermediate build stages (downloaded dependencies, compiler caches) should be exported.
- Make a cache toggle control both restore and export. If it intentionally
  controls only one direction, name it `restore_cache` or `export_cache`.
- Treat `pull: true` and layer caching as independent: refresh referenced base
  images without implying `no-cache`.
- Do not store credentials in cacheable layers or build arguments. Use BuildKit
  secret or SSH mounts for build-time credentials.
- Add QEMU/binfmt only when a build executes target-architecture binaries.
  Omit it when a toolchain runs on `$BUILDPLATFORM` and cross-compiles artifacts
  for `TARGETOS`/`TARGETARCH`.
- When changing cache behavior or claiming reuse/performance improvements, use
  comparable hosted runs to prove restore/export and reuse. Configuration alone
  proves wiring. Do not require cache experiments for unrelated workflow edits.
- When GHCR retention is in scope, run cleanup only after successful image
  publication, in a job with `packages: write`. Preserve the repository's retention
  policy. For `dataaxiom/ghcr-cleanup-action`, protect persistent/rolling release
  channels (e.g. `latest`, `stable`, `edge`) in `exclude-tags`:

  ```yaml
  - name: Delete old images
    uses: dataaxiom/ghcr-cleanup-action@d52806a0dc70b430571a37da1fde39733ffd640f # v1.2.2
    with:
      keep-n-tagged: 10
      keep-n-untagged: 10
      exclude-tags: latest
      delete-partial-images: true
  ```

## Releases and Supply Chain

- Keep tests read-only and grant release/package writes only after verification
  succeeds.
- Publish immutable version or commit-derived tags. Add a mutable channel such
  as `latest` only when its update semantics are deliberate.
- Capture and expose the pushed image digest. Pin deployed runtime images by
  digest even when a mutable tag is used as a build-stage input.
- Prefer OIDC over long-lived cloud credentials.
- Generate provenance once through a deliberate mechanism. Add SBOM generation
  when consumers or policy use it; avoid duplicate attestations by default.
- Use protected environments for production publication or deployment when a
  manual approval or environment-scoped secret boundary is valuable.

## Reliability and Validation

- Add `timeout-minutes` to bound stuck jobs.
- Consider `parallel` for independent steps within one job; execution continues
  after the group finishes. Use `background: true` for asynchronous steps,
  `wait`/`wait-all` to synchronize, and `cancel` to stop background services.
  Check the [workflow syntax documentation](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax#jobsjob_idstepsparallel)
  before implementation.
- Scope concurrency to the release unit and apply the sequence checks in Execution
  Selection before enabling cancellation or replacing pending runs. Keep reusable
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
- Finish with `git diff --check` and a focused diff review. State which behavior
  was validated locally, which was verified in Actions, and which remains
  pending a trusted publish or deployment event.
