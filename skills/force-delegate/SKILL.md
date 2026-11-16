---
name: force-delegate
description: Coordinate an explicitly requested task through existing subagents while the main agent supervises, integrates, and validates the result. Use when invoked as $force-delegate or explicitly requested by name.
---

# Force Delegate

Apply this mode to the supplied task, or the active task when no argument is
given. If neither identifies a task, ask what to accomplish. Infer the expected
result and completion criteria from the request and conversation. Ask for a
definition of done only when material acceptance criteria remain unclear;
reuse criteria already agreed. Keep this mode active through follow-ups for
the same task until those criteria are met or the user changes the mode.
Do not extend it to unrelated tasks in the session.

## Delegate execution

Delegation is required in this mode. Send substantive execution to at least one
actual subagent, including the assignment's focused verification; do not merely
propose delegation or treat it as optional.
Use one delegate for tightly coupled or sequential work. Do not fall back to
doing the assignment yourself because parallelism is unavailable or handoff is
less convenient. The main agent owns framing, scope, decisions, communication,
integration, final diff inspection, decisive validation, and acceptance.

Orient only enough to define the first useful assignment; delegate discovery
when it is itself substantial. Work reserved to the main agent by applicable
permission or ownership rules stays with the main agent. If delegation fails
or is not permitted, report the obstacle and ask whether to proceed directly.
Await that answer before taking over the delegated assignment. If the user
chooses direct execution, end this mode for the task and report that switch;
do not claim delegation happened.

## Reuse the configured team

Choose the role from the assignment: `worker` for implementation and focused
tests, `explorer` for codebase discovery, `researcher` for external research,
and `default` for other work. Use the configured model and reasoning settings
and honor the user's overrides. State the chosen team, known settings,
assignment boundaries, and acceptance checks once. Reuse earlier choices;
do not ask the user to choose a role when the assignment already determines it.
Handle actual dispatch failures as described above; do not add a preliminary
availability inventory.

For implementation, plan the existing `reviewer` as the default independent
reviewer unless the user overrides that choice. Ask once, early in the agreed
delivery scope, whether the user also wants AGY or another named reviewer.
Make answering easy: offer the default reviewer alone and the default reviewer
plus AGY; allow a named alternative in free text. Ask for a model or reasoning
level only when the selected alternative has no usable configured default.
The default reviewer is already independent of implementation; this question
is about an additional review. Reuse an existing answer instead of asking
again each turn or after each fix. An unanswered question leaves extra review
unselected; continue execution, validation, and the default review.

For selected AGY review, read the installed `agy:reviewer` skill before dispatch
and use its jobs workflow for collection. Report an unavailable selected
reviewer and ask before substituting unless a fallback is already authorized.
Do not start a review round for research-only or formatting-only work unless
the user requests it or a concrete risk warrants it.

## Dispatch, collect, and accept

Give each delegate a compact assignment: goal, owned files or read-only scope,
relevant context, user constraints and authorizations, acceptance criteria,
required evidence, and stop condition. Prefer fresh compact context over the
whole conversation. Keep one writer per ownership area and use only useful
parallelism within available capacity. Delegation does not expand permissions;
commits, pushes, deployments, and final integration remain with the main agent.

Collect each result before making dependent claims. While waiting, do only
independent work; do not repeat the delegated investigation. Assess the actual
artifacts and consequential choices against the assignment, inspect relevant
diffs, and perform the decisive checks. Fix small integration defects directly;
send substantive gaps back as focused follow-ups. Do not rerun every worker
check without a new failure, change, or unresolved concern.

For implementation, send the stable combined result and requirements to the
default reviewer with fresh context, without the implementer's conclusions.
Run any user-selected extra review independently as well; that explicit choice
permits an additional reviewer beyond the usual one broad review. Resolve
actionable findings and verify their fixes with focused checks or a focused
follow-up to the same reviewer. Preserve any stronger required review evidence
from applicable repository instructions.

Before reporting completion, confirm that at least one actual delegate returned
a relevant result, inspect the final diff or artifact, and check acceptance evidence.
Report delegate identities and outcomes, which reviews actually ran, decisive
validation, and remaining blockers or unperformed checks. Dispatch alone is not
completion; a missing selected review remains unperformed.
