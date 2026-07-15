# Project document contract

Use only the documents relevant to the project. Merge into existing canonical
files rather than creating parallel plans.

## `spec.md`

Keep the specification decision-oriented:

1. Goal and first end-to-end user scenario.
2. KISS and convention-over-configuration principles.
3. Explicit MVP scope and exclusions.
4. Public contracts: CLI, HTTP, data, files, or library API.
5. Required persistence, security, and operational behavior.
6. Dependencies with reasons, not just a technology list.
7. Hardcoded conventions and the few allowed configuration values.
8. Testing and delivery requirements selected by the user.
9. Measurable Definition of Done.

Remove historical alternatives after a decision. Record deferred alternatives
in `docs/future-ideas.md` only when they are likely to be revisited.

## `docs/implementation-plan.md`

Make this the only prioritized backlog:

- state the review, test, acceptance, and commit loop;
- list small vertical packages in delivery order;
- give each package concrete acceptance criteria;
- keep checkboxes open until validation and agreed acceptance are complete;
- avoid dates, speculative phases, duplicate future work, and PR promises.

Bootstrap packages may establish tests and automation, but do not let repository
machinery delay the first usable vertical slice without an explicit user choice.

## `docs/future-ideas.md`

Create this file only when useful. State prominently that it is neither a
backlog nor a commitment. Use unprioritized bullets without checkboxes, owners,
or dates. Move an idea into the MVP only through an explicit decision that also
updates the spec and implementation plan.

## `AGENTS.md`

Record durable repository behavior:

- canonical spec, backlog, and optional future-ideas roles;
- KISS and convention-over-configuration rules;
- package review and authorization gates;
- official-documentation and version-verification policy;
- dependency, image, Action, and Go-tool pinning rules selected by the user;
- approved repo-local Go skills, their source, and update/review workflow;
- canonical test, lint, and CI commands once they exist;
- protection of generated or agent-owned directories from formatters.

Do not copy the whole specification into `AGENTS.md`. Keep only rules a future
agent must apply while changing the repository.
