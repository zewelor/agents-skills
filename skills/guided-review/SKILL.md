---
name: guided-review
description: Guide review of Git changes with optional independent review and explicit human commit approval. Use when explicitly requested or invoked as $guided-review, not for ordinary review.
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
- Ask optional questions about material changes to how people use or operate the system.
- Treat answers as discussion. Require an explicit request to implement changes.
- Apply the commit gate to each package. Require separate authorization to publish.
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
| `$guided-review` | Detect the relevant change scope, automatically decide whether it can be split, stage the next coherent package when needed, self-review it, validate it, and explain practical consequences. Review an explicitly supplied full scope without changing Git state. |
| `$guided-review next` | Approve the current package. If the [commit gate](#gate-commits-and-the-next-package) passes, commit it and prepare the next chunk in the same turn. |
| `$guided-review auto [scope]` | Prepare one coherent package if the index is empty, run [two reviews of the staged package](#review-one-staged-package-in-auto), and report its readiness. |
| `$guided-review auto $adversarial-review` | Use the explicitly invoked adversarial review as the independent review of the staged package. |
| `$guided-review second-opinion` | Run a manually requested independent review using a source selected by the user. |
| `$guided-review explain` | Explain a selected part of the current scope or produce a concrete scenario/counterexample without changing code. |

Accept clear natural-language equivalents, including “zrób review tej zmiany”,
“przygotuj następną paczkę”, “zrób self-review”, and “tak, commituj i zacznij nową
paczkę”. Do not interpret an answer alone as commit approval.

## Select a review scope

1. Prefer an explicit scope from the user: a staged diff, commit range, branch/PR,
   file set, or named package.
2. Before staging anything, inspect the existing index. If it already contains
   changes, use it as a prepared package only when it matches one complete package
   in the requested scope (or as the candidate scope when none was given).
   Otherwise leave it intact and ask before rebuilding it.
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
5. Stage the next ready package and leave the remaining candidates unstaged.
   If no safe split is clear, stage the complete relevant change as one package.

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
5. Use an adopted index as-is. For a new package, stage only the selected files or
   hunks. Use explicit paths, interactive staging, or a
   narrowly generated index patch. Recheck `git status --short`, the staged name list,
   and the staged diff. Set the review mode to `prepared_package` only after confirming
   that the index contains exactly one coherent selected package and no known unrelated
   changes.

## Summarize the review

Give one summary after review and validation. State what changes, the exact
scope, findings, and validation results. Include gaps or assumptions that
affect approval. Keep routine summaries brief and explain material risks.

For a prepared package, include the staged files or hunks, the staged fingerprint,
and the draft commit message before asking for approval. For an automatically
selected package, mention remaining packages or why the scope was kept together.
Call out important related changes left unstaged. Put any optional question last.

Give substantive changes a concise commit subject and a short
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

For a full-scope review, inspect the selected range, paths, or staged diff without
staging, editing, committing, or splitting it into packages. Use the same review
and validation guidance. Do not allow `next` to commit a full-scope review unless
the user explicitly asks to prepare a staged package first.

## Choose a review focus

Focus on the aspects relevant to the change:

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

Evaluate whether the implementation is worthwhile. Apply security review where
the actual change warrants it.

## Review only the selected scope

Inspect only the selected diff and the minimum surrounding context needed to understand
it. For a staged review, use `git diff --cached` and read relevant code, including
unchanged dependencies, from the same index tree. Give any independent reviewer
context from that tree. For a full-scope review, respect the user-provided range or
paths. Use evidence-backed findings with this shape:

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

Separate observations from decisions. Report unresolved decisions in the
findings and leave product, architecture, and risk acceptance decisions to the
user. If a disputed contract determines whether the package is correct, flag it
as a `BLOCKER` and ask which contract to implement.

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
- Record commands, outcomes, checked state, reused results and why they apply, and
  remaining gaps. Distinguish local, synthetic, unavailable, and deployment evidence.

For a prepared package, record the base commit (or unborn branch for an
initial commit) and full index tree after final validation as the staged fingerprint.
Use `git --no-pager rev-parse --verify HEAD` for an existing base and
`git --no-pager write-tree` for the tree. A diff hash alone does not identify the
complete staged snapshot. If the base or tree changes, review the delta and renew
affected validation before allowing `next`. Retain evidence for unaffected checks.

## Discuss changes people will notice

Use `$explain` for a hard-to-follow before/after consequence. Ground it in a task
the user performs, such as using a shortcut, handling a changed default, or
recovering from a failed deploy.

If `$explain` is unavailable, explain in plain technical language and follow
ASD-STE100 for English.

Offer one optional question when a package materially changes how someone uses,
configures, or operates the system and their answer could reveal a preference or
misunderstanding that matters to that workflow. Reuse decisions already made in
the conversation. For tests, formatting, documentation cleanup, and internal
refactors with unchanged user-facing behavior, summarize the impact and omit the
question.

Close the question if the user declines to answer. If the user misunderstands
the consequence or asks for help, explain it once without another question.
An optional question never gates a commit.

## Review one staged package in auto

Honor an explicit request for read-only full-scope review. Treat any scope supplied to
`auto` as a constraint on the package. Inspect the index first:

- If the index is empty, use [Prepare the selected package](#prepare-the-selected-package)
  to select and stage one coherent package from eligible worktree changes, then continue
  the review in the same turn. If the requested scope contains no changes (including an
  explicitly staged-only scope with an empty index), report that and stop.
- If the index already contains one coherent package in scope, adopt it as-is.
- If the index is mixed or outside the requested scope, propose one concrete package
  and wait for approval before rebuilding the index.

Use `prepared_package` for the selected package.

Review and validate the package yourself. [Select one reviewer](#select-an-independent-reviewer).
When the user also invokes `$adversarial-review`, use that skill with the same
reviewer and staged fingerprint.
If the requested skill is unavailable or the selected review cannot run,
report `HOLD`.

Give the independent reviewer the staged diff, fingerprint, user scope, intended
behavior, relevant context and check results within the approved disclosure scope.
Withhold your own findings on its first pass. Ask for evidence of failures, lost
coverage, missing prerequisites or scope violations, and its verdict on that
fingerprint.

Check each material objection against the diff, contract or a focused run. Give the
reviewer your evidence if you disagree. Report `READY` only when required checks pass,
the independent reviewer has assessed every material acceptance criterion, and both
agents accept the same fingerprint.
Otherwise report `HOLD` with the concrete objection or missing evidence, your
assessment and what would resolve it.

End the invocation with the verdict and a brief review summary. Leave the package
staged for the user. If the base or index changes, renew both reviews and affected
checks and present the new verdict before asking for approval.

## Gate commits and the next package

Apply this gate only in `prepared_package` mode. Keep `full_scope` read-only.
Allow a local commit only when all of these conditions hold:

- the review mode is explicitly `prepared_package`;
- the index contains exactly one coherent selected package and no known unrelated changes;
- the current staged diff is the one that was reviewed and validated;
- the base (including unborn state) and full index tree match the fingerprint recorded after final
  validation in this review session (recompute both immediately before committing);
- the current conversation contains a review for that exact staged diff;
- for an `auto` package, the latest verdict reported to the user for that fingerprint is `READY`;
- after receiving the review, validation, fingerprint and any required verdict,
  the user explicitly approves committing that package (for example, with `next`);
- no unresolved `BLOCKER` finding remains, or the user explicitly acknowledges and
  rejects that finding;
- `git diff --cached --check` passes.

If approval arrives early, present the review, validation, and fingerprint and
wait for fresh approval.

Before committing, finalize the displayed draft using the commit-message rules
above, check it against the staged diff, and apply any user-requested wording
changes. Commit only the index contents using that message.
Show the resulting commit and worktree status, never push implicitly, then automatically
select and prepare the next package in the same turn when `next` was requested.

If the user asks to change the implementation after the review, update the package
explicitly, restage only its intended scope, and rerun the affected review and validation.

## Select an independent reviewer

For `auto` or `second-opinion`, use the reviewer the user selected for this review.
Otherwise ask “Codex subagent or AGY reviewer?” and wait for the choice.
For Codex, use a read-only subagent. For AGY, invoke `$agy:reviewer` in the
target repository and honor any explicit sharing limits.

## Run a manual second opinion

[Select one reviewer](#select-an-independent-reviewer). Also accept a named tool,
a supplied review report, or cancellation when requested. If it is unavailable, report that fact and
ask whether to use another source; do not silently substitute one. Give a local
subagent only the selected diff and necessary context (the staged diff for a prepared
package),
and instruct it not to edit files, commit, push, or publish a verdict. For another external
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
new issue, apply the optional-question rule only to the new finding. Treat a
changed selected scope as making both opinions stale.

## Explain without editing

For `$guided-review explain` and natural follow-ups such as “why?”, use
`$explain` or the [fallback above](#discuss-changes-people-will-notice).
Answer the point the user asked about. Stop after the explanation unless that
message also contains an explicit commit or `next` request. Apply the normal
commit gates to that request. Keep the explanation read-only.
