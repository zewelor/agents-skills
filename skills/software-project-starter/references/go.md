# Go project decisions

Inspect the selected Go version, module, commands, packages, and verification
workflow. Prefer standard-library facilities and shallow packages until actual
responsibilities justify more structure. Prefer direct SQL when persistence
needs no framework; keep abstractions tied to present consumers and behavior.

For new Go executables, keep code and colocated tests in `cmd/<binary>/`, even
for small single-package CLIs. Preserve established layouts and public library
import paths.

Follow idiomatic names, explicit error wrapping, context propagation for I/O,
graceful cancellation, and ownership of concurrent state. Justify interfaces
through a real boundary or implementation need rather than future possibilities.
Record selected tools with `go get -tool` when supported by the project's Go
version; verify version-sensitive syntax before modifying the toolchain.

When Renovate is selected, use the project's shared Go preset if available;
preserve local exceptions and verify its effective settings. When Go versions
are declared in multiple places, group the Go module, build image, and CI version updates using their actual
Renovate dependency names. Keep CI reading `go.mod` where practical. Configure
the `go` directive to bump alongside the toolchain and record that this raises
the minimum supported Go version. Validate extraction, grouping, and version
replacements for the project's declarations; preserve its automerge policy.

For each Go module, keep `go.mod` and `go.sum` tidy and configure CI to run
`go mod tidy -diff` with the project Go version. When Renovate is selected,
ensure the shared preset or local configuration enables `postUpdateOptions: ["gomodTidy"]` so dependency PRs include tidy changes.
Review the resulting module changes; retain sums that Go still requires.

Choose validation for the contracts that exist: command/API behavior, persistence,
failure recovery, and cancellation. Use the race detector for shared-state
concurrency and built-in fuzzing for meaningful input properties when warranted.

## Go skills

Inspect existing project skills and the current catalog:

```text
npx skills add samber/cc-skills-golang --list
```

Start with `golang-code-style`, `golang-error-handling`, and `golang-testing`.
Reuse equivalent project guidance and explain omitted baseline capabilities.
Add candidates for actual project needs, for example `golang-cli` for CLIs,
`golang-context` for cancellation/deadlines, `golang-security` for secrets or
networking, `golang-database` for SQL, and `golang-concurrency` for concurrent work.
Discover other candidates from the catalog rather than treating these examples
as an exhaustive list.

Read shortlisted descriptions and relevant instructions; keep the smallest set
that fits the contract without overlapping guidance or conflicting requirements.
Follow the [shared workflow](automation.md#select-repository-local-skills) for
installation, verification, and recording the selection and its reasons.
