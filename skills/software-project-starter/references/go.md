# Go project decisions

Inspect the selected Go version, module, commands, packages, and verification
workflow. Prefer standard-library facilities and shallow packages until actual
responsibilities justify more structure. Prefer direct SQL when persistence
needs no framework; keep abstractions tied to present consumers and behavior.

Follow idiomatic names, explicit error wrapping, context propagation for I/O,
graceful cancellation, and ownership of concurrent state. Justify interfaces
through a real boundary or implementation need rather than future possibilities.
Record selected tools with `go get -tool` when supported by the project's Go
version; verify version-sensitive syntax before modifying the toolchain.

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
