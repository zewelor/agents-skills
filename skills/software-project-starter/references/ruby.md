# Ruby project decisions

Identify CLI, library/gem, Rails application, or a combination before choosing
layout. Inspect existing Gemfile/gemspec, entrypoint, runtime declarations,
task commands, Docker wrappers, autoloading, linting, tests, and deployment.

## CLI and library

- Keep argument parsing and process behavior in a thin `bin/<name>` entrypoint;
  keep reusable domain behavior in `lib/<namespace>/`. Use OptionParser when it
  covers the commands; justify a larger CLI framework through actual needs.
- Establish help, input validation, exit status, stdout/stderr, and any promised
  machine-output contract. Make errors explicit; preserve Ruby falsey values and
  the distinction between string/symbol keys where the public API relies on it.
- Use Bundler for selected dependencies. Add gem packaging for an actual
  distribution requirement; declare packaged files, executables, version, and
  minimum Ruby deliberately. Distinguish a runnable bin/lib tool from a gem.
- Choose host Ruby/mise or the existing Dockerized Bundler workflow according
  to supported execution. Keep Ruby/Bundler declarations aligned across the
  files actually used; do not create a second competing version knob.
- Preserve the chosen lockfile policy. Prefer tracking application locks for
  reproducible deployment; decide library/development lock handling from
  distribution and CI requirements rather than copying an unlocked template as
  a universal default.
- Preserve StandardRB or the existing lint stack. Add Zeitwerk only when the
  namespace/layout benefits justify it; with Zeitwerk, match files to constants,
  use explicit nesting for new namespaces, and keep internal loading consistent.
- Reuse the current Minitest/RSpec setup. Add a reproducible scenario through the
  real command and realistic fixtures; verify packaged execution outside the
  source directory when distribution is part of the contract. Test boundaries
  absent from E2E without duplicating its coverage.

Treat a starter's declared testing commands as intentions until the harness
exists and runs. Inspect the selected Docker targets before inheriting a large
multi-stage template into a small tool.

## Rails

Keep Rails' existing layout, migrations, ORM, test stack, and framework-owned
boundaries. Apply the same MVP and verification decisions without importing Go
package or direct-SQL defaults. Use DHH/37signals style guidance only when the
user or repository explicitly adopts it; keep plain Ruby CLI guidance separate.

Verify version-sensitive Ruby, Bundler, Zeitwerk, and Rails behavior in official
documentation before adding exact syntax or making toolchain changes.
