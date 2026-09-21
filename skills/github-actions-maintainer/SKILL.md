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
   third-party actions, caches, artifacts, and publication side effects.
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
- Let Renovate or Dependabot maintain action references and review major-version
  changes deliberately.
- Set `persist-credentials: false` on checkout unless later steps intentionally
  perform authenticated Git operations.

## Docker, GHCR, and Buildx Cache

Use the Docker skill for Dockerfile stages, build context, image contents,
runtime users, and BuildKit cache mounts. Keep workflow orchestration here.

- Authenticate to a private registry before any build step whose `FROM` may
  pull a private image.
- Build and smoke-test the native runner platform before publishing a
  multi-platform manifest when this gives useful fast feedback.
- Configure Buildx cache with both `cache-from` and `cache-to`. Select the backend based on workflow triggers and cache sharing requirements:
  - Use `type=gha,scope=${image_name}` for branch and PR workflows where builds run on `main` or feature branches and inherit branch cache without extra registry tags or package write permissions.
  - Use `type=registry,ref=${registry}/${image}:buildcache` when workflows are triggered from release tags (`refs/tags/v*`), release branches, or manual dispatches. GitHub Actions cache does not share across independent tag refs, whereas an OCI cache artifact in GHCR/registry is ref-independent, allowing new releases (`vX.Y.Z`) to reuse cache from previous tags.
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
- Prove cache behavior from at least two comparable workflow runs. Configuration
  proves wiring; logs showing cache import and cached layers prove reuse.
- Clean up GHCR packages after image publication in jobs with `packages: write` using `dataaxiom/ghcr-cleanup-action`. Protect all persistent/rolling release channels (e.g. `latest`, `stable`, `edge`) in `exclude-tags`:

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
- Add concurrency groups for replaceable CI and use `cancel-in-progress: true`
  there. Do not cancel release or deployment jobs unless replacement is proven
  safe.
- Prefer an explicit runner generation when reproducibility outweighs automatic
  runner updates.
- Keep shell commands fail-fast and quote variables. Avoid embedding secrets in
  command lines or logs.
- Run repository-native validation first. Run `actionlint` and `zizmor` when
  already available; do not install missing tools automatically without user
  approval.
- Parse every changed workflow as YAML and inspect the complete caller/callee
  permission chain.
- For Docker workflows, run the narrow Dockerfile lint and smoke build defined
  by the repository. Treat a successful native smoke build as different from a
  successful multi-platform push.
- Finish with `git diff --check` and a focused diff review. State which behavior
  was validated locally, which was verified in Actions, and which remains
  pending a trusted publish or deployment event.
