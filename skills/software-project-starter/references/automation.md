# Select project tooling

Inspect existing tooling and reuse earlier user choices. Keep the default CI
checks proportional to the project and use its actual verification commands.
Bundle material unresolved choices into a compact question; reuse stated
exclusions and prior authorization instead of asking again.

Resolve other optional surfaces only where relevant: Docker/Compose, persistence
and migrations, releases, image platforms, SBOM/scanning/signing, local hooks,
and changelog automation. Keep rejected machinery out of the scaffold. Preserve
tools already required by the project contract.

## Configure selected automation

- Verify supported stable tool versions and APIs against official documentation.
  Use prereleases only when explicitly selected; keep runtime declarations aligned.
- Pin Actions by full commit SHA with a version comment and container images by
  digest. Configure only required dependency managers and update classes.
- Default GitHub Actions workflows to `ubuntu-latest`. Use another runner only
  for a concrete project requirement; explain a fixed Ubuntu version in an
  adjacent YAML comment.
- For Renovate, use existing shared presets when adopted by the project, retain
  local exceptions, and establish automerge scope. Verify effective rules and CI
  protections. If `$renovate-maintainer` is available,
  read it before choosing the configuration location or creating the file; follow
  its guidance for managers and package rules. For CI, establish blocking checks.
  Publish only selected image platforms; justify release machinery and dependencies.
- Keep credentials in the project's established secret mechanism. Keep required
  configuration explicit and failures visible.
- Use an existing task runner. Add a justfile only for useful shared commands
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

Include justified project-local skills in an authorized bootstrap; for planning-only
work, recommend without installing. Allow an empty set when existing project guidance
suffices. Reuse delegated selection/install approval; ask once for the concrete set
only when installation is outside the granted scope. Respect user exclusions.
Do not change global skills or add unrelated tools, dependencies, or project scope.

Consider [software-engineering](https://github.com/zewelor/agents-skills/blob/main/skills/software-engineering/SKILL.md)
as an optional candidate when focused coding guidance would fill a real gap;
omit it when existing instructions are sufficient. Read its description and
instructions before selecting it. If selected, use this source with the shared
installation settings below:

```sh
npx skills add zewelor/agents-skills --skill software-engineering
```

Install selected skills with `npx skills add <source> --skill <name>` and the chosen
agent/copy settings. For an approved copy/all-agent setup, use repeated `--skill`
options with `--agent '*' --copy -y`. Verify `.agents/skills`, provenance in
`skills-lock.json`, and `npx skills list --json`. Report discovery/install failures
and unverified checks; continue independent work without claiming installation
succeeded. Keep the starter usable without companions.

Record the selection, brief reasons, and update policy in existing project docs.
Update individual skills with `npx skills update <skill-name> -p -y`; inspect local
divergence first and review installed files and lock metadata afterward. Keep
authoring changes in the source repository; do not overwrite divergent local edits.
Keep skill installation separately reviewable. Exclude agent-owned directories
from linting and formatting.
