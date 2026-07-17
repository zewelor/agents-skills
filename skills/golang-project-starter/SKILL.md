---
name: golang-project-starter
description: Design and bootstrap small, opinionated Go projects from an idea or early repository. Use when starting a Go service, CLI, worker, or library; turning requirements into a written specification and implementation plan; re-scoping an overdesigned Go starter toward a minimal MVP; or deciding project conventions, dependencies, testing, containers, native Git hooks, Renovate, GitHub Actions, and delivery workflow before implementation.
---

# Go Project Starter

Turn an idea into the smallest coherent Go project contract, get it reviewed,
then implement it incrementally. Prefer KISS and convention over configuration.

## 1. Inspect before asking

- Read repository instructions, status, existing docs, manifests, and source.
- Preserve user changes and established conventions unless the user explicitly
  wants a reset.
- Reuse an existing canonical spec or plan instead of creating duplicates.
- Discover facts from the repository before asking the user.

## 2. Run focused discovery

Use `request_user_input` when available; otherwise ask concise plain-text
questions. Ask one to three high-leverage questions per round, recommend the
simplest option first, and explain its tradeoff.

Establish only decisions that materially change the project:

1. Define the first user-visible outcome and the smallest end-to-end scenario.
2. Identify the project shape: service, CLI, worker, library, or combination.
3. Record non-negotiable runtime, persistence, security, and operational needs.
4. Ask whether the user wants specification only or implementation after
   explicit review.
5. Ask how packages should be reviewed, tested, accepted, and committed.

Ask follow-up questions only when answers affect the contract. Do not turn
discovery into a generic questionnaire.

## 3. Minimize the MVP

- Require every feature to support the first end-to-end scenario.
- Prefer one resource, one format, one identity, and one write path initially.
- Prefer required inputs over parallel optional behaviors when one convention
  covers the known use case.
- Prefer standard library code and direct SQL over frameworks or abstraction
  layers that have no current payoff.
- Avoid interfaces without a second implementation, plugin systems, generic
  repositories, speculative fallbacks, and future-proof factories.
- Expose configuration only for secrets and values that genuinely differ
  between environments. Hardcode safe product conventions and operational
  defaults.
- Keep security, data integrity, recovery, and operational features when the
  user marks them critical. Minimal must not mean unsafe.
- Move plausible but unneeded ideas to a non-prioritized parking lot. Do not
  silently preserve them in the architecture.

State assumptions and challenge contradictions. If a retained feature forces
extra configuration or dependencies, make that cost explicit.

## 4. Decide optional project machinery

Ask explicitly before adding each optional surface; do not infer consent from
the fact that it is common in Go repositories:

- Renovate;
- GitHub Actions;
- Docker or Docker Compose;
- release automation, multi-arch images, SBOM, scanning, or signing;
- database and migration tooling;
- repo-local agent skills;
- changelog or release-note automation.

Before finalizing a full project bootstrap, ask a direct automation question
that names Renovate and GitHub Actions. Recommend skipping both for a tiny or
local-only project, but require an explicit selection. Do not treat silence or
their appearance in an exclusions list as approval.

For Renovate, ask which managers and update classes should automerge. For
GitHub Actions, ask which checks must block delivery. Skip both when the project
does not need hosted automation yet.

When selected:

- verify current stable versions in official documentation and upstream;
- reject prereleases unless explicitly approved;
- pin container images by digest;
- pin Actions by full commit SHA with a version comment;
- record Go tools with `go get -tool`;
- configure Renovate only for dependency types actually present;
- justify every runtime dependency during review.

When Docker is selected:

- Create and maintain a root `.dockerignore`.
- Add a root `Justfile` with this inspection target:

  ```just
  test_dockerignore:
    rsync -avn . /dev/shm --exclude-from .dockerignore
  ```

- Run `just test_dockerignore` and inspect the dry-run file list before accepting
  container-related changes.

When local Git hooks are selected:

- Prefer Git's native, tracked `.githooks/` directory and a repository-local
  `core.hooksPath` over Husky, pre-commit, Lefthook, or another hook manager
  unless a concrete cross-platform or orchestration requirement justifies one.
- Add an explicit bootstrap command such as `just hooks-install` that runs
  `git config --local core.hooksPath .githooks`; Git intentionally does not
  activate repository-provided hooks automatically after clone.
- Put a slow complete quality gate such as `just ci` in `pre-push`, not
  `pre-commit`, so iterative commits remain fast.
- Keep hosted CI authoritative. Treat local hooks as an early feedback layer,
  document their installation, and exclude `.githooks/` from Docker build
  contexts when the hooks are not required by an image.

## 5. Select repo-local Go skills

If the user opts into repo-local agent skills, inspect the current catalog
before proposing a shortlist:

```text
npx skills add samber/cc-skills-golang --list
```

Select only skills justified by the accepted project contract:

- `golang-code-style`, `golang-naming`, `golang-modernize`,
  `golang-error-handling`, and `golang-testing` for most maintained projects;
- `golang-project-layout` when the project needs multiple packages or commands;
- `golang-context` for I/O, cancellation, servers, workers, or databases;
- `golang-database` only when persistence is selected;
- `golang-concurrency` only for goroutines, workers, pipelines, or shared state;
- `golang-security` for secrets, authentication, untrusted input, or network
  services;
- `golang-dependency-management` when external modules or update automation are
  present;
- `golang-lint` when linting is part of the accepted validation surface;
- `golang-continuous-integration` only when hosted CI is selected.

Present the shortlist and reasons for user approval. Do not install every skill
for completeness. After approval, install selected skills from
`samber/cc-skills-golang` with repeated `--skill <name>`, `--agent '*'`,
`--copy`, and `-y`. Verify `.agents/skills`, `skills-lock.json`, and:

```text
npx skills list --json
```

Record the exact selected set in the spec and implementation plan. Put skill
installation in its own reviewed bootstrap package, exclude `.agents/` from
formatters and pre-commit tools, and update one project-scoped skill through:

```text
npx skills update <skill-name> -p -y
```

Review every skill update separately; never overwrite divergent local edits.

## 6. Write the contract before code

Create or update only the documents the project needs. Read
`references/project-docs.md` for the required contents.

Use these default roles:

- `spec.md`: canonical product and technical contract;
- `docs/implementation-plan.md`: the only prioritized backlog;
- `docs/future-ideas.md`: optional, non-prioritized parking lot;
- `AGENTS.md`: durable repository workflow and conventions.

Keep the documents concise and consistent. Put a decision in one canonical
place and link to it elsewhere. Include measurable Definition of Done based on
the first end-to-end scenario.

Present the spec, explicit exclusions, unresolved decisions, and package plan
for review. Do not scaffold implementation before the user accepts the contract
unless they explicitly waive this gate.

## 7. Plan vertical packages

- Prefer a small number of end-to-end packages over horizontal architecture
  layers.
- Give every package a user-visible or operational acceptance criterion.
- Keep future packages out of the current diff.
- Use this recommended loop when the user agrees:
  implementation, project test command, review, corrections, retest, explicit
  acceptance, then one local commit.
- Require separate authorization for pushes, pull requests, releases, or other
  externally visible actions.

Choose the smallest validation surface that proves the package. Add a `Justfile`
only when it provides a useful canonical interface over multiple commands.
Prefer containerized integration tests when the selected runtime dependency
requires them, not as a universal default.

Treat the Docker inspection target above as sufficient reason for a `Justfile`
when Docker is selected.

## 8. Implement without widening scope

- Build the thinnest working vertical slice first.
- Follow idiomatic Go naming, package boundaries, context propagation, error
  wrapping, and graceful cancellation.
- Keep package structure shallow until independent responsibilities emerge.
- Add tests around contracts, concurrency, persistence, and failure modes that
  are actually present.
- When Docker is present, review `.dockerignore` after every file-layout change,
  especially after adding root-level files or directories. Add or update the
  relevant patterns deliberately, run `just test_dockerignore`, and verify the
  resulting file list before accepting the change.
- Re-run the agreed acceptance command after corrections.
- Stop for review at the agreed gate; do not self-approve packages.

When a new need appears, update the spec and backlog deliberately instead of
activating a hidden extension point.
