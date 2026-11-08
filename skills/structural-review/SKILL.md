---
name: structural-review
description: Review code for implicit state machines, broken invariants, unclear ownership, and needless structural complexity. Select relevant original review questions and return a few evidence-backed priorities with actionable follow-ups. Use for a requested structural review; ordinary implementation and session retrospectives are separate tasks.
---

# Structural Review

Find consequential structural problems and useful simplifications in the
relevant code. Review by default; implement changes only when the user's
request also authorizes them.

## Establish the scope

Honor an explicit target. With a bare invocation, infer the scope from the
conversation, working changes, and repository purpose. Use these as starting
points and follow relevant relationships across components and workflows.
State the chosen scope and reason. Ask only when a missing decision would
materially change scope.

Read applicable repository instructions and relevant implementation, callers,
and tests. Establish the contract before treating a helper's behavior as a
user-visible bug. For state-machine discovery, map the machines within scope
and their shared state and interactions before prioritizing findings. Honor
an explicitly requested complete inventory.

## Select original questions

Keep the source wording below unchanged. Select the questions relevant to
the task and evidence; use them to open investigative directions. Keep the
operating guidance in the following sections separate from these questions.

### Discover state machines

> find all of the implicit state machines in my app

### Reconsider the abstraction

> What higher-level abstraction would make this entire problem disappear?

### Reduce the state space

> minimize the state space and make illegal states unrepresentable

### Look for a native mechanism

> is there a native way of doing this that would be cleaner?

### Challenge the design

> Design the single test that breaks this design on day one.

### Seek a simpler solution

> Is there a simpler, dumber way to accomplish this that my engineer will appreciate more?

## Establish evidence and compare options

Trace reachable sequences through actual callers, including meaningful
transitions, terminal conditions, and recovery. Examine ownership and shared
state across flags, records, caches, queues, files, and external services.
Where relevant, check retries, concurrency, partial success, interruption,
expiration, and whether accepted input satisfies the next stage's needs.
Distinguish accepted best-effort behavior from a contract violation.

Treat a local correctness failure as a finding even when the overall model
remains adequate. Trace success and rejection or failure through transaction
and cleanup boundaries; establish which mutations persist in each case.
Check whether existing tests exercise the specific failure sequence; test
names and nearby happy paths alone do not establish coverage. Use a focused
isolated reproduction when practical and permitted. Otherwise label the
claim as source-based or as a hypothesis and identify the missing check.

Compare a promising model change with a local correction and existing
project, language, or framework mechanisms. Explain which concrete problems
each option removes and whether it preserves required behavior. Keep an
adequate design when no improvement is justified. Do not invent a failure
or require a new abstraction to satisfy a question.

Rank by concrete impact, reachability, and strength of evidence. Consider
effort when choosing the next action. Avoid numerical scores without a real
measurement. Continue relevant investigation until the evidence supports
the leading findings or a justified no-change result. Use the report limit
to select what to present; do not stop discovery merely because three
findings are available. State material coverage and verification limits.

## Return a short decision

State the scope and selected questions briefly. By default, present up to
three important findings, fewer when warranted. For each, give:

- the trigger and observable consequence;
- the evidence with precise code locations and verification status;
- the smallest useful next action, phrased as an executable follow-up request.

Separate confirmed defects from hypotheses and optional simplifications.
Recommend an order when there are multiple actions. Keep low-value notes out
of the main result and avoid a full checklist table. State material skipped
checks briefly. If no consequential problem is established, say so without
manufacturing findings. Match the user's language.
