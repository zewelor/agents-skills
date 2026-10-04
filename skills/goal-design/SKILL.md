---
name: goal-design
description: Draft or review evidence-based goals for multi-step agent work in any domain, including implementation, research, diagnosis, optimization, migration, and document creation. Use when asked to prepare a goal or when uncertain completion criteria need clarification; keep small, straightforward tasks as ordinary requests.
---

# Goal Design

Turn the user's intent into a concise, verifiable outcome. Preserve the task's
scope and leave room to choose the approach as evidence develops.

## Ground the goal

- Read the relevant instructions and available artifacts before defining success.
  Reuse established requirements, decisions, and authorization.
- Identify the result the user needs and the decision it enables. Separate
  competing outcomes into distinct goals; keep correctness and preservation
  requirements as constraints on the main outcome.
- Ask only for missing information that materially changes the goal. Label
  unresolved assumptions instead of inventing requirements or numerical targets.
- Keep a small, straightforward task as an ordinary request. Do not turn every
  assignment into a persistent goal or a new planning document.

## Define completion

Specify only the details needed to make the outcome auditable:

- **Outcome:** State what must be true when the work is complete.
- **Evidence:** Name the artifact, observation, comparison, or reproducible check
  that demonstrates the result. Establish a baseline when claiming improvement.
- **Constraints and scope:** Define allowed inputs and changes, required
  guarantees, and the limits of existing authorization.
- **Continuation:** Describe how new evidence should guide the next useful step;
  avoid prescribing a fixed sequence, tool, or technique unless required.
- **Stopping:** Distinguish verified completion from unavailable evidence,
  exhausted permitted approaches, and a resource limit. Preserve any user-set
  budget; propose a limit only when its absence creates a material problem.

For research or diagnosis, allow a supported negative or unresolved conclusion
when appropriate. Require the evidence, its limits, and the smallest missing
observation. Do not require a positive finding or claim certainty from absence.

## Challenge the draft

- Identify plausible ways an agent could satisfy the wording while missing the
  user's need: weaken a check, optimize a proxy, ignore relevant inputs, replace
  observation with inference, or produce an artifact without verifying it.
- Tighten the relevant criteria without adding a universal checklist. Distinguish
  available evidence from assumed results and prevent silent weakening of the
  agreed success condition.
- Keep discovery and verification separable. Use independent review when the
  uncertainty or consequences justify it and delegation is available; do not
  require a fixed agent count or orchestration system.
- For analysis of variants of a known failure, describe the failure class and
  relevant conditions without prescribing the exact location or expected answer.

## Deliver the goal

Return a ready-to-use goal in the user's language, followed only by material
assumptions or unresolved choices. Reuse existing project documents rather than
creating duplicate plans or status records.

Use this compact shape when helpful:

> Achieve <outcome>, verified by <evidence>, while preserving <constraints>.
> Work within <scope>. Choose subsequent steps from the observed results.
> If verification is blocked or permitted approaches are exhausted, report
> <evidence gathered, limitations, and the next required input>.

Activate a persistent Goal only when the user explicitly requests it. Treat a
request to draft or review a goal as preparation. If execution is already
authorized, proceed within that scope without asking for the same approval again.
Use the available goal mechanism and relevant domain guidance; do not implement
a separate continuation loop or import a domain-specific audit workflow.
