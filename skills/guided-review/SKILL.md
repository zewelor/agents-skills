---
name: guided-review
description: Interactive Git workflow for reviewing an existing change scope or automatically preparing one or more coherent staged packages, validating them, asking concise comprehension questions, optionally obtaining a manually requested independent second opinion, and committing only after explicit user approval. Use when a user explicitly asks for a guided review of code, configuration, documentation, or infrastructure changes, invokes $guided-review, wants to understand a repository change before approving it, or requests an interactive commit-and-next flow.
---

# Guided Review

Use this skill to guide a human through an evidence-backed review of a repository change.
Support both review of an existing scope and automatic package selection/staging for
worktree changes. Keep the user in control of the review and publication decisions.

## Operating contract

- Treat the user-selected scope as the review boundary. Use the staged diff as the
  boundary for a prepared package.
- Decide automatically whether the selected work can be split into independently valid
  packages. Do not ask the user to choose a splitting mode.
- Stage only selected paths or hunks when preparing packages; never use `git add .` or an
  equivalent broad add. Stage the whole relevant scope when no safe split exists.
- Preserve unrelated staged, unstaged, and untracked work.
- Review only the selected diff plus the minimum relevant repository context.
- Run focused, repository-approved validation before reporting the selected scope as ready.
- Ask the user a short set of high-level comprehension questions after the review.
- Treat quiz answers as evidence of understanding, not as implicit implementation requests.
- Wait for explicit approval before committing or publishing.
- Never push as part of this workflow unless the user separately requests it.

Call each independently reviewable change package a **chunk** (spójna paczka zmian).
Choose automatically whether the current scope is one chunk or a sequence of chunks;
never ask the user to choose a chunking mode.

Do not silently unstage, discard, reset, overwrite, or reformat unrelated work. Treat an
existing staged diff as a candidate user boundary, not as automatically commit-ready.
Adopt it only when it matches the requested task and contains one coherent package. If it
mixes relevant and unrelated changes, keep Git state unchanged, block the commit path,
and ask only for authorization to rebuild the index. After authorization, choose the
package boundary automatically; do not ask the user how to split it. Stop and ask when
the relevant scope itself cannot be identified safely or when completing the task would
require rewriting an existing staged boundary.

Track the review mode explicitly: `full_scope` is read-only, while `prepared_package` is
the only mode that can pass the commit gate. Do not infer one mode from the other.

## Command meanings

Interpret these commands and their natural-language equivalents as follows:

| Command | Meaning |
| --- | --- |
| `$guided-review` | Detect the relevant change scope, automatically decide whether it can be split, stage the next coherent package when needed, self-review it, validate it, and ask comprehension questions. Review an explicitly supplied full scope without changing Git state. |
| `$guided-review next` | After the current chunk passed review, validation, and the understanding gate, treat this invocation as fresh commit approval, commit only the reviewed staged diff, and automatically prepare the next chunk when one remains. If no current chunk has passed those gates, run them and wait for a later approval. Do not push. |
| `$guided-review second-opinion` | Run a manually requested independent review using a source selected by the user. |
| `$guided-review explain` | Explain a selected part of the current scope or produce a concrete scenario/counterexample without changing code. |

Accept clear natural-language equivalents, including “zrób review tej zmiany”,
“przygotuj następną paczkę”, “zrób self-review”, and “tak, commituj i zacznij nową
paczkę”. Do not interpret a mere answer to the quiz as commit approval. Do not ask the
user whether the work should be split; make that determination from the changes.

## Select a review scope

1. Prefer an explicit scope from the user: a staged diff, commit range, branch/PR,
   file set, or named package.
2. If a staged diff exists and the user asks for review without another scope, inspect
   that diff and do not add worktree changes. Adopt it as a prepared package only when it
   matches the requested task and contains one coherent intent. If it is mixed or does
   not match the task, report the mismatch, keep Git state unchanged, block the commit
   path, and ask whether the user authorizes rebuilding the index.
3. If the user explicitly requests a full or read-only review, leave Git state unchanged.
4. If no staged diff exists and the user asks to review or prepare current worktree
   changes without requesting read-only review, treat all related changes as the
   candidate scope and decide automatically whether to stage one package or the whole
   scope.
5. Keep unrelated worktree changes outside the candidate scope and report them.
6. If the requested scope cannot be identified safely, report the ambiguity and wait.

For a full-scope review supplied as a commit range, branch/PR, or explicit file set,
leave Git state unchanged and set the review mode to `full_scope`. For current worktree
changes, follow the automatic package selection procedure below, make the staged package
the review boundary, and set the review mode to `prepared_package`.

## Automatically select a package

1. Map changed files and hunks to their intent, dependency, ordering, tests, fixtures,
   and contract documentation.
2. Form candidate packages that could each be reviewed, validated, and understood on
   their own. Keep code with the tests and documentation required to make its behavior
   complete.
3. Build a dependency order between candidates. Treat a candidate as ready only when
   its prerequisites are already in the base revision or included in that same package.
4. Reject a split when a candidate would leave an invalid intermediate state, lose a
   required test or contract, or require another package to explain its behavior.
5. If two or more ready candidates remain, choose the smallest coherent next package,
   stage it, and report the remaining candidate packages without staging them.
6. If no safe split remains, stage all relevant changes as one package and explain why.
7. If the split or dependency order is uncertain, prefer one complete package over an
   artificial sequence.

Do not split only by file count or line count. Use semantic independence, topological
ordering, and a complete validation boundary. Validate the selected candidate before
reporting it as ready. Do not stage unrelated changes merely to avoid asking the user.

## Prepare the selected package

1. Read the nearest repository instructions before editing or validating. Follow any
   repository-specific staging, test, check-mode, deployment, and documentation rules.
2. Inspect the worktree without changing it:
   - `git status --short`
   - `git diff --cached --name-status`
   - `git diff --name-status`
   - relevant untracked paths
3. If a staged diff already exists, check whether it matches the requested task and is
   one coherent intent. Adopt it as the current package only when both checks pass. Do
   not add other changes to it. If it is mixed, remain read-only and request authorization
   to rebuild the index; do not ask the user to choose the resulting package boundary.
4. If no staged diff exists, apply the automatic package-selection procedure above.
5. If the user proposes a package boundary, evaluate it as a constraint, but keep
   responsibility for checking completeness and dependencies.
6. Stage only the selected files or hunks. Use explicit paths, interactive staging, or a
   narrowly generated index patch. Recheck `git status --short`, the staged name list,
   and the staged diff. Set the review mode to `prepared_package` only after confirming
   that the index contains exactly one coherent selected package and no known unrelated
   changes.
7. Show the user:
   - the package purpose and boundary;
   - the staged files/hunks;
   - remaining candidate packages or the reason the scope was kept whole;
   - important related changes deliberately left outside staging;
   - any ambiguity or assumption used to select the package.

Report the selected scope in a stable order: boundary, review agenda, findings,
validation, then comprehension questions. For an automatically prepared package, also
report remaining candidate packages or why the scope was kept whole. Keep the summary
short enough for the user to inspect the actual diff themselves.

Call a package “minimal” only when it is the smallest safe and understandable unit, not
when it merely contains the fewest files. Avoid splitting a behavior change from its
required test or contract documentation.

## Review an existing scope

For a full-scope review, keep the selected Git state unchanged. Show the exact range,
paths, or staged diff being reviewed, then inspect it without staging, editing, committing,
or splitting it into packages. Apply the same review agenda, evidence-backed findings,
proportional validation, and comprehension questions. Do not allow `next` to commit a
full-scope review unless the user explicitly asks to prepare a staged package first.

## Build a review agenda

Before inspecting details, state a short, change-specific agenda. Select only relevant
lenses from this list:

- **Intent and value:** Confirm that the change addresses the stated problem and that
  its operational or maintenance cost is justified.
- **Correctness and failure paths:** Trace normal, empty, stale, first-run, retry, and
  failure cases that the change can encounter.
- **Simplicity and alternatives:** Look for a smaller, clearer, or more robust design;
  identify unnecessary helpers, fallback layers, duplicated conditions, or mixed
  refactors.
- **Contract and compatibility:** Check defaults, interfaces, ordering, idempotence,
  upgrade behavior, and interactions with existing callers or inventory.
- **Validation:** Check whether tests and probes exercise the changed behavior and
  whether the claimed evidence is synthetic, check-mode-only, or live.
- **Operational and security risk:** Apply this lens when the package can reboot,
  lock out, expose data, alter network access, send content to an external tool, or
  affect production state.

Do not assume that an idea is worthwhile merely because it is already implemented. Do
not turn every review into a generic security audit; adapt the agenda to the actual
change.

## Review only the selected scope

Inspect only the selected diff and the minimum surrounding context needed to understand
it. For an automatically prepared package, use `git diff --cached` and keep unrelated
worktree changes out of findings. For a full-scope review, use the user-provided range,
paths, or staged diff without expanding it. Use evidence-backed findings with this shape:

```text
**[BLOCKER|SHOULD-FIX|NIT]** path:line — short description

Issue: concrete behavior or risk, including the triggering condition.
Evidence: code, command output, test, or documented contract supporting it.
Suggestion: smallest reasonable correction or follow-up.
Confidence: high|medium|low.
```

Use `BLOCKER` only for correctness, safety, data-loss, security, or deployment issues
that should stop the package. Use `SHOULD-FIX` for material bugs or design problems.
Use `NIT` for optional clarity or style improvements. Report “no findings in the
reviewed scope” rather than declaring the package universally approved.

Separate observations from decisions. Do not make the user’s product, architecture,
or risk acceptance decision on their behalf.

## Validate proportionally

- Run `git diff --cached --check` for an automatically prepared package, or the
  equivalent check for the selected full-scope diff, before declaring the review complete.
- Run the narrowest relevant syntax checks, tests, linters, render checks, or check-mode
  probes required by the repository instructions and the package’s risk.
- Prefer repository-provided runners and project-local tools.
- Never apply a production or remote configuration merely to validate a package.
- Report exact commands and outcomes. Distinguish passed local checks from checks that
  remain synthetic, unavailable, or pending a real deployment.
- After the final package validation, record a fingerprint of the exact staged content,
  for example `git diff --cached --binary | sha256sum`, and show it with the validation
  result. If the staged diff changes after review or validation, mark the prior review
  stale and repeat the affected review, questions, and checks before allowing `next`.

## Ask comprehension questions

Ask only as many questions as the selected scope needs, normally two to five and fewer
for a small obvious change. Use “package” for an automatically prepared package and
“scope” for a full review. Prefer questions that require the user to explain the behavior:

- What changes for the default path?
- Under what condition does the new path run or fail?
- What does the change deliberately leave untouched?
- Why is this package boundary reasonable? (Ask only for an automatically prepared
  package.)
- What scenario or counterexample would expose a mistake?

Avoid trivia about line numbers, syntax, or names. Use a concrete scenario when a
conditional, ordering rule, retry, or state transition is hard to reason about. Accept
brief answers and assess whether the user understands the selected scope at a practical
level.

After the answers, report a short result:

```text
Zrozumienie: wystarczające | wymaga doprecyzowania

Dobrze rozumiane:
- ...

Do doprecyzowania:
- ...
```

If understanding is insufficient, explain the gap plainly and ask only the smallest
follow-up needed. Do not keep quizzing indefinitely. If an answer proposes a code or
scope change, state that it is a separate decision and wait for explicit authorization
before editing or restaging. Treat understanding as insufficient when the user cannot
explain the package intent, important behavior, boundary, or material risks. Record minor
nonessential unknowns separately, but do not use risk acceptance to convert a material
understanding gap into a passing result. If the user declines this gate, do not commit
under this workflow.

## Gate commits and the next package

Keep the prepared package staged and wait after the questions. Apply this commit gate
only in `prepared_package` mode and for `$guided-review next`; keep `full_scope` review
read-only. Allow a package commit only when all of these conditions hold:

- the review mode is explicitly `prepared_package`;
- the index contains exactly one coherent selected package and no known unrelated changes;
- the current staged diff is the one that was reviewed and validated;
- a staged fingerprint was recorded in the current review session after final validation;
- the current staged fingerprint matches that recorded value (recompute it immediately
  before committing);
- the current conversation contains a review and understanding result for that exact
  staged diff; otherwise repeat the review gate instead of trusting an older session;
- after receiving the findings, validation result, understanding result, and staged
  fingerprint, the user explicitly says to commit or invokes `$guided-review next` in a
  later message; earlier, conditional, or blanket authorization does not count;
- no unresolved `BLOCKER` finding remains, or the user explicitly acknowledges and
  rejects that finding;
- the user’s understanding is sufficient;
- `git diff --cached --check` passes.

Before committing, derive a concise message from the staged package only. Commit only
the index contents. Show the resulting commit and worktree status, never push implicitly,
then automatically select and prepare the next package in the same turn when `next` was
requested.

If the user asks to change the implementation after the review, update the package
explicitly, restage only its intended scope, and rerun the review and questions. Do not
use the quiz as a hidden requirements-gathering mechanism.

## Run a manual second opinion

Keep this path opt-in. Do not start a subagent or call an external MCP reviewer during
the normal package flow.

When the user invokes `$guided-review second-opinion` without naming a source, ask for
one of:

1. a local read-only subagent;
2. a named agent or MCP tool;
3. a review report supplied by the user;
4. cancellation.

Honor an explicitly named available source. If it is unavailable, report that fact and
ask whether to use another source; do not silently substitute one. Give a local
subagent only the selected diff and necessary context (the staged diff for a prepared
package),
and instruct it not to edit files, commit, push, or publish a verdict. For an external
MCP or service, show the exact data scope before sending it and obtain confirmation;
accept an explicit instruction such as “send this diff to MCP X” as that confirmation,
but do not treat naming a tool alone as consent to disclose the diff. Redact secrets and
unrelated content, and send only the minimum review context.

Keep the second opinion independent: do not reveal the primary findings to it unless the
user explicitly asks to critique those findings. Present the returned result separately,
then compare:

- agreements;
- new findings;
- disagreements or different assumptions;
- decisions required from the user.

Do not merge a second opinion into the code automatically. If it introduces a material
new issue, ask only delta comprehension questions. Treat a changed selected scope as
making both opinions stale.

## Explain without editing

For `$guided-review explain`, focus on the selected file, hunk, condition, or reported
finding. Use a small example, state transition, before/after comparison, or
counterexample. Keep the explanation tied to the current selected scope. Do not edit,
restage, commit, or reinterpret the user’s answer as approval.
