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
