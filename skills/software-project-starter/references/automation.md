# Select project tooling

Inspect existing tooling and reuse earlier user choices. Keep the default CI
checks proportional to the project and use its actual verification commands.
Bundle material unresolved choices into a compact question; reuse stated
exclusions and prior authorization instead of asking again.

Resolve other optional surfaces only where relevant: Docker/Compose, persistence
and migrations, releases, image platforms, SBOM/scanning/signing, local hooks,
changelog automation, and repository-local skills. Keep rejected machinery out
of the scaffold. Preserve tools already required by the project contract.

## Configure selected automation

- Verify supported stable tool versions and APIs against official documentation.
  Use prereleases only when explicitly selected; keep runtime declarations aligned.
- Pin Actions by full commit SHA with a version comment and container images by
  digest. Configure only required dependency managers and update classes.
- For Renovate, establish automerge scope. For CI, establish blocking checks.
  Publish only selected image platforms; justify release machinery and dependencies.
- Keep credentials in the project's established secret mechanism. Keep required
  configuration explicit and failures visible.
- Use an existing task runner. Add a Justfile only for useful shared commands
  or the selected Docker context inspection target; avoid parallel command layers.

## Configure selected local hooks

Preserve an existing hook manager. For a new setup, prefer tracked `.githooks/`
and local `core.hooksPath` when native hooks cover the requirement; justify an
extra manager by a real portability or orchestration need.

Provide an explicit installation command, such as `git config --local core.hooksPath
.githooks`, through the chosen project task interface. Put the slow complete
quality gate in pre-push and keep pre-commit fast. Keep hosted CI authoritative
when selected; exclude hook files from images that do not need them.

## Select repository-local skills

Inspect the current source catalog and propose only skills needed by the
contract. Reuse approved selections; resolve missing install authorization before
mutating the skill environment. Keep the skill itself usable without companions.

After selection, use `npx skills add <source> --skill <name>` for named skills;
use the project's agent/copy settings and verify `.agents/skills`, installation
metadata in `skills-lock.json`, and `npx skills list --json`. For targeted updates,
use `npx skills update <skill-name> -p -y`. Inspect local divergence first and
review the installed diff; keep authoring changes in the source repository.

Record selected skills and update/review policy in the project documents. Keep
skill installation as a separately reviewable bootstrap step when it affects the
project workflow. Exclude agent-owned directories from linting and formatting.
