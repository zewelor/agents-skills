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

## Select optional Go skills

Use this section when the user requests companion skills or approves a proposal
addressing a concrete gap; otherwise skip catalog lookup and selection. Once
companion installation is in scope, inspect the current catalog:

```text
npx skills add samber/cc-skills-golang --list
```

Map candidates to actual responsibilities:

- Consider `golang-code-style`, `golang-naming`, `golang-modernize`,
  `golang-error-handling`, and `golang-testing` for maintained Go work.
- Add `golang-project-layout` for multiple packages or commands.
- Add `golang-context` for I/O, cancellation, services, workers, or databases.
- Add `golang-database` for selected persistence and `golang-concurrency` for
  goroutines, workers, pipelines, or shared state.
- Add `golang-security` for secrets, authentication, untrusted input, or networking.
- Add `golang-dependency-management` for external modules or dependency automation.
- Add `golang-lint` and `golang-continuous-integration` only for selected lint/CI.

Resolve selection with the user and install only approved skills. Use the
project's chosen agent and copy settings. For an approved copy/all-agent setup,
use repeated `--skill <name>`, `--agent '*'`, `--copy`, and `-y`. Review generated
directories and lock metadata after installation.
Keep this catalog as candidates rather than a mandatory bundle.
