---
name: guided-review
description: Guide an interactive review of Git changes with practical understanding checks and approved commits. Use when explicitly requested or invoked as $guided-review, not for ordinary review.
---

# Guided Review

Use this skill to guide a human through an evidence-backed review of a repository change.
Support both review of an existing scope and automatic package selection/staging for
worktree changes. Keep the user in control of the review and publication decisions.

## Operating contract

- Treat the user-selected scope as the review boundary. Use the staged diff as the
  boundary for a prepared package.
- Stage only selected paths or hunks when preparing packages; never use `git add .` or an
  equivalent broad add. Stage the whole relevant scope when no safe split exists.
- Preserve unrelated staged, unstaged, and untracked work.
- Review only the selected diff plus the minimum relevant repository context.
- Run focused, repository-approved validation before reporting the selected scope as ready.
- Check the user’s practical understanding of the change and its consequences after the review.
- Treat replies as evidence of understanding, not as implicit implementation requests.
- Wait for explicit approval before committing or publishing.
- Never push as part of this workflow unless the user separately requests it.

Call each independently reviewable change package a **chunk** (spójna paczka zmian).

Do not silently unstage, discard, reset, overwrite, or reformat unrelated work. Treat an
existing staged diff as a candidate user boundary, not as automatically commit-ready.
Follow the scope-selection rules below before adopting or changing that boundary.

Track the review mode explicitly: `full_scope` is read-only, while `prepared_package` is
the only mode that can pass the commit gate. Do not infer one mode from the other.

## Command meanings

Interpret these commands and their natural-language equivalents as follows:

| Command | Meaning |
| --- | --- |
| `$guided-review` | Detect the relevant change scope, automatically decide whether it can be split, stage the next coherent package when needed, self-review it, validate it, and check practical understanding. Review an explicitly supplied full scope without changing Git state. |
| `$guided-review next` | Treat this invocation as explicit approval to commit the current reviewed package and automatically prepare the next chunk. Evaluate any accompanying replies. When every gate passes after the review, validation, fingerprint, and comprehension check, commit and prepare the next chunk in the same turn. If it arrives before those materials, run the gates and wait for later approval. Do not push. |
| `$guided-review second-opinion` | Run a manually requested independent review using a source selected by the user. |
| `$guided-review explain` | Explain a selected part of the current scope or produce a concrete scenario/counterexample without changing code. |

Accept clear natural-language equivalents, including “zrób review tej zmiany”,
“przygotuj następną paczkę”, “zrób self-review”, and “tak, commituj i zacznij nową
paczkę”. Do not interpret an answer alone as commit approval.

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

Choose package boundaries automatically.

1. Map changed files and hunks to their intent, dependency, ordering, tests, fixtures,
   and contract documentation.
2. Group changes that serve one purpose and can be reviewed and validated as one
   decision. Keep code with the tests and documentation required to make its
   behavior complete.
3. Build a dependency order between candidates. Treat a candidate as ready only when
   its prerequisites are already in the base revision or included in that same package.
4. Split when a concrete difference in purpose, effect, or risk warrants a
   separate review decision. Reject splits that leave an invalid intermediate
   state, omit a required test or contract, or require another package to explain
   the change.
5. Stage the next ready package and report the remaining candidates without
   staging them. If no safe split is clear, stage the complete relevant change
   as one package and explain why.

Validate the selected package before reporting it as ready. Keep unrelated
changes outside the package.

## Prepare the selected package

1. Read the nearest repository instructions before editing or validating. Follow any
   repository-specific staging, test, check-mode, deployment, and documentation rules.
2. Inspect the worktree without changing it:
   - `git status --short`
   - `git diff --cached --name-status`
   - `git diff --name-status`
   - relevant untracked paths
3. Follow “Select a review scope” for an existing staged diff. If no staged diff exists,
   apply the automatic package-selection procedure above.
4. If the user proposes a package boundary, evaluate it as a constraint, but keep
   responsibility for checking completeness and dependencies.
5. Stage only the selected files or hunks. Use explicit paths, interactive staging, or a
   narrowly generated index patch. Recheck `git status --short`, the staged name list,
   and the staged diff. Set the review mode to `prepared_package` only after confirming
   that the index contains exactly one coherent selected package and no known unrelated
   changes.
6. Show the user:
   - the package purpose and boundary;
   - the staged files/hunks;
   - remaining candidate packages or the reason the scope was kept whole;
   - important related changes deliberately left outside staging;
   - any ambiguity or assumption used to select the package.

Report the selected scope in a stable order: boundary, review agenda, findings,
validation, the draft commit message for a prepared package, then the comprehension
check. For an automatically prepared package, also report remaining candidate
packages or why the scope was kept whole. Keep the summary short enough for the
user to inspect the actual diff themselves.

Include a draft commit message in each prepared package summary, before requesting
answers or commit approval. Give substantive changes a concise subject and a short
body documenting the problem or trigger, why this approach was chosen, and any established
tradeoffs, so a future reader can reconstruct the decision. Start with the established
reason, then explain how the package addresses it; do not substitute a diff summary
or generic benefit for the motivation.

Use a subject alone for an obvious typo or mechanical formatting correction with no
change in behavior, meaning, or contract and no non-obvious decision to explain.
Respect an explicit user request about the body. Judge significance by consequences,
not line count: a one-line policy or behavior change can still require the rationale.

Ground the change in the staged diff and its motivation in established user,
repository, or review context. Reuse that rationale without asking the user to
reconfirm it. When a required rationale remains unclear after inspecting available
context, ask a focused question before finalizing the draft; never invent the reason.
Follow repository commit conventions and refresh the draft when the package changes.
For example:

```text
refactor(nvim): use built-in EditorConfig

Neovim already applies EditorConfig rules by default, so the plugin
is redundant. Remove it to avoid maintaining the extra dependency.
```

## Review an existing scope

For a full-scope review, keep the selected Git state unchanged. Show the exact range,
paths, or staged diff being reviewed, then inspect it without staging, editing, committing,
or splitting it into packages. Apply the same review agenda, evidence-backed findings,
proportional validation, and comprehension check. Do not allow `next` to commit a
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

- Run `git --no-pager diff --cached --check` for a prepared package, or the equivalent
  check for a full-scope review. Honor repository-required checks and hooks.
- Select the smallest checks covering the changed behavior, plausible failures, and
  affected callers or shared contracts. Select existing tests by relevance, including
  tests unchanged by the package; do not limit selection to staged test files. Prefer
  repository runners and local tools. Use syntax/reference checks for documentation;
  do not invent tests that assert source text or merely detect staging.
  Expand by impact from the changed behavior; an unchanged import alone does not
  justify testing a dependency or sibling feature.
- Run a full suite only when the repository requires it or a concrete unresolved risk
  cannot be checked more narrowly. Staging, another package, `next`, or a new reviewer
  alone does not justify a full-suite run.
- Before running tests, check prior passing results. If the relevant code, tests,
  fixtures, dependencies, and environment match the index, count those checks as
  validated; do not rerun them merely because files were staged. After a change, rerun
  only affected checks and explain any broader run. Pass evidence to a requested
  reviewer without prescribing their findings.
- Establish evidence for the package's index contents: a matching worktree result is
  sufficient. If excluded worktree changes affected the checked inputs, validate the
  affected behavior in an isolated staged snapshot instead. Treat missing staged
  prerequisites as a package gap, even when the complete worktree passes.
- If a required check or pre-commit hook fails and unrelated work may be involved,
  rerun the failed check in an isolated staged snapshot under repository policy.
  If it passes, report the likely isolation problem and suggest a separate hook/runner
  fix; otherwise diagnose the failure. Change hooks or runners only when requested.
- Never apply production or remote configuration merely to validate a package.
- Report commands, outcomes, checked state, reused results and why they apply, and
  remaining gaps. Distinguish local, synthetic, unavailable, and deployment evidence.

For a prepared package, record and show the base commit (or unborn branch for an
initial commit) and full index tree after final validation as the staged fingerprint.
Use `git --no-pager rev-parse --verify HEAD` for an existing base and
`git --no-pager write-tree` for the tree. A diff hash alone does not identify the
complete staged snapshot. If the base or tree changes, review the delta and renew
affected validation and comprehension evidence before allowing `next`; retain
evidence for unaffected checks.

## Check practical understanding

In the review summary, use `$explain` to present the material before/after
consequences. If `$explain` cannot be loaded, write the explanation in plain
technical language inspired by ASD-STE100. Use short sentences, consistent terms,
and explicit causes and consequences. Then follow the comprehension check below.

For a non-obvious change, show one concrete scenario that explains what happened
before, why the change affects that path, and what the caller observes after.
Check whether the user can predict how the change affects use, configuration,
compatibility, or failure handling. Use “package” for a prepared package and
“scope” for a full review.

Ask only about material gaps not already resolved by the conversation. Use concrete
scenarios and accept brief answers. If the explanation already gives the answer,
check whether the user can apply it in a different scenario. Do not set a question
quota or quiz unchanged rules, implementation trivia, or the agent's package choices
unless they have material consequences. Rephrase unclear questions before assessing
the answer.

When earlier replies demonstrate understanding of the reviewed change, cite that
evidence instead of asking again. This completes the comprehension check, not
commit approval.

After the comprehension check, report a short result:

```text
Zrozumienie: wystarczające | wymaga doprecyzowania

Dobrze rozumiane:
- ...

Do doprecyzowania:
- ...
```

If a message contains explicit commit approval and understanding is sufficient,
report the result and continue through the commit gate in the same turn. Do
not pause for duplicate confirmation. If understanding is insufficient, do not carry
that approval forward to a later clarification.

If understanding is insufficient, explain the gap plainly and ask only the smallest
follow-up needed. Do not keep asking indefinitely. If an answer proposes a code or
scope change, state that it is a separate decision and wait for explicit authorization
before editing or restaging. Treat understanding as insufficient when a material
gap in understanding the change’s purpose or consequences remains unresolved.
Record minor nonessential unknowns separately, but do not use risk acceptance to
convert a material understanding gap into a passing result. If the user declines
this gate, do not commit under this workflow.

## Gate commits and the next package

Keep the prepared package staged until understanding is sufficient and the user
explicitly approves committing; allow replies and approval in the same message.
Apply this commit gate only in `prepared_package` mode and for an explicit commit
or `next` request; keep `full_scope` review read-only. Allow a package commit only
when all of these conditions hold:

- the review mode is explicitly `prepared_package`;
- the index contains exactly one coherent selected package and no known unrelated changes;
- the current staged diff is the one that was reviewed and validated;
- the base (including unborn state) and full index tree match the fingerprint recorded after final
  validation in this review session (recompute both immediately before committing);
- the current conversation contains a review for that exact staged diff and sufficient
  comprehension evidence under the check above; report the understanding result
  in the same turn before or alongside the commit outcome;
- after receiving the findings, validation result, staged fingerprint, and comprehension
  check, the user explicitly says to commit or invokes `$guided-review next`; allow
  that request to accompany replies, but do not count approval given before those
  materials or unrelated blanket authorization;
- no unresolved `BLOCKER` finding remains, or the user explicitly acknowledges and
  rejects that finding;
- `git diff --cached --check` passes.

Before committing, finalize the displayed draft using the commit-message rules
above, check it against the staged diff, and apply any user-requested wording
changes. Commit only the index contents using that message.
Show the resulting commit and worktree status, never push implicitly, then automatically
select and prepare the next package in the same turn when `next` was requested.

If the user asks to change the implementation after the review, update the package
explicitly, restage only its intended scope, and rerun the review and comprehension
check. Do not use the comprehension check as a hidden requirements-gathering mechanism.

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

For `$guided-review explain` and natural follow-ups such as “why?”, use `$explain`
and the same fallback as in the [review summary](#check-practical-understanding).
Explain the point the user asked about within the current selected scope. Resume
the understanding check only if it was already in progress and incomplete
when the user asked. Otherwise, stop after the explanation. Do not edit, restage,
commit, or reinterpret the user’s answer as approval.
