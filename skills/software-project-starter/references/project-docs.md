# Project document contract

Reuse existing canonical files and names. Scale documentation to the project:
keep a tiny project's contract and short plan in one document; use the following
roles for work that benefits from separate documents.

Choose a combined contract/plan or separate files. Keep task lists and status in
exactly one location; link to the backlog from other documents instead of copying
its steps or checkboxes. For a specification-only request, record the intended
agent handoff in the contract. During an authorized bootstrap, add durable agent
guidance when future work needs it.

## `spec.md`

Record the decisions needed to build and verify the project:

1. Goal, project shape, and first realistic end-to-end scenario.
2. MVP scope, required guarantees, and explicit exclusions.
3. Public contracts: CLI, HTTP, files, data, UI flows, or library API.
4. Runtime, distribution, persistence, security, and recovery requirements.
5. Chosen stack and dependencies with concrete reasons.
6. Fixed conventions and the few necessary configuration values.
7. Testing decisions, including PBT/stateful/formal-methods assessment.
8. Selected tooling, review loop, and delivery authorization.
9. Measurable Definition of Done consistent with every retained feature.

This is a menu, not a required template: omit items that do not affect this
project, and keep the resulting contract as short as practical.

Replace obsolete decisions instead of appending contradictory history. Move
deferred alternatives to the parking lot only when they are worth revisiting.

## Quality bar

Record standing quality requirements beside the Definition of Done in the
existing contract. Reuse an existing constraints document if the project has
one; avoid creating a second source of truth. Keep task acceptance criteria in
the plan and link to the standing requirements.

- Choose only dimensions justified by this project's risks and user needs.
  Reuse existing tools; do not install a scanner or coverage tool just to fill
  out a checklist.
- Pair each requirement with its reason, exact check command, evidence artifact
  when needed, and blocking or advisory status. Distinguish an enforced rule
  from a target whose checker is unavailable or not yet implemented.
- Measure an existing baseline before proposing a numerical budget. For a new
  project, use a justified user target or gather representative evidence first;
  avoid arbitrary coverage percentages or web metrics for a CLI.
- Place fast focused checks in the development loop, relevant acceptance checks
  at slice completion, and the complete required E2E suite at delivery. Put
  expensive checks in CI or an explicit verification stage when selected;
  preserve required checks even when they exceed a preferred time budget.
- Investigate new suppressions, skipped or deleted tests, weakened assertions,
  and lowered thresholds. Record justified replacements or exceptions with a
  reason and scope; keep failures visible rather than weakening the agreed bar
  to make a change pass.

## `docs/implementation-plan.md`

Keep this as the only prioritized backlog. Plan a small number of vertical
slices with scope, dependencies, observable acceptance criteria, and verification
commands. Keep checkboxes open until validation and agreed acceptance finish.
Keep arbitrary dates, speculative phases, and unapproved publication promises out.

Fold setup and documentation into the slice that needs them; separate bootstrap
work only when it has an independently useful acceptance criterion. Keep the
plan usable by a fresh session without duplicating the full specification or
writing the entire application in advance.

## `docs/future-ideas.md`

Create only when there are deferred ideas worth preserving; otherwise omit it.
Label it as neither a backlog nor a commitment. Keep
unprioritized bullets without checkboxes, owners, or dates. Promote an idea only
through a scope decision reflected in the contract and prioritized plan.

## `AGENTS.md`

Create or update this during an authorized bootstrap when durable project
guidance will help future work; omit it for a tiny project with no such need.
Record project-specific information that future work needs: canonical document
locations, domain invariants, selected runtime/toolchain, exact verification
commands, established review/delivery gates, and relevant directory boundaries.
Document selected local skills and their update workflow without copying their
instructions. Keep generated and agent-owned directories out of formatters.

Include a short durable reminder, linked to the project's testing decisions:

> Reassess property-based testing, stateful/model-based testing, and formal methods
> before substantial changes to public contracts, state transitions, or
> concurrency. Record adopt / pilot / skip with the expected benefit and cost.

Link to the project's actual decision document; keep the reminder self-contained
and independent of the author's notebook or machine paths. Keep agent guidance
limited to durable rules rather than duplicating the specification.
