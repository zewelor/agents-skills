---
name: adversarial-review
description: Challenge a change or design with an independent reviewer and verify material failure claims. Use only when the user explicitly invokes $adversarial-review, alone or with $guided-review auto.
---

# Adversarial Review

Review and report. Keep source files, staged contents, refs, and live systems unchanged.
Put any probes or fixtures in an isolated temporary workspace.

## Establish the target and intent

1. Honor the supplied scope and focus. With a bare invocation, use the current
   agreed review target, then a nonempty index, then the relevant branch and
   working changes relative to the merge base with an established base branch.
   Include relevant untracked files only in a worktree review. Record the exact
   target and exclusions. For a plan, identify the version or supplied text.
2. State in your own words what the change must achieve and why. Identify the
   contracts and constraints that define failure. Use the request, change
   rationale, and repository context. Ask one focused question only if the
   target, baseline, or intended behavior still materially changes the review.
3. Pin the review to the selected state. For staged work, use the base commit
   (or unborn state) and full index tree as the fingerprint. Read all relevant
   code, including unchanged dependencies, from that tree. Use the same tree
   for the independent reviewer's code context. Run checks affected by unstaged
   changes in an isolated index snapshot. For PRs and ranges, identify the
   reviewed revisions.
   Recheck the target before reporting and tie the evidence to the reviewed state.

## Dispatch an independent reviewer

If the user has not selected a reviewer for this review, ask them to choose the
configured read-only Codex `reviewer` or `$agy:reviewer`. Wait for the selection
before dispatch. Give the selected reviewer fresh context for the first pass
and honor any specified model the host supports. Add a second reviewer only on
explicit request for distinct coverage. When paired with
`$guided-review auto`, use its staged target and run one independent reviewer
in its existing review slot. Give that reviewer the same fingerprint and request
an explicit accept or hold with any material uncertainty.

Give each reviewer the target, intent, constraints, focus, and relevant check
results within the approved disclosure scope. On the first pass, withhold your
conclusions and other reviewers' findings. Ask what plausible input, state, or
sequence would violate the change's contract. Prioritize material regressions,
missing prerequisites, and failure paths. For each candidate request the trigger,
location, consequence, reproduction command, and observed versus expected
result, or the specific check still needed. For plans, ask for a small prototype
or a probe of current behavior where feasible. Accept an empty findings list
with coverage limits.

When the user chooses AGY, run `$agy:reviewer` from the target repository.
Use Neon High unless the user specifies another model. Honor any explicit limits
on what may be shared; if the runner cannot meet them, ask before dispatch.

Report a missing review or unavailable model and ask before substituting
another reviewer.

## Verify and report

- Independently rerun each material candidate on the pinned target. Use the
  smallest safe check that shows the actual and expected behavior. For a claimed
  regression, compare with the base when needed to attribute it to the change.
  Use the normal entry point and relevant runtime configuration when the claim
  depends on them. For a new enforcement rule, check both a violation and a
  nearby allowed case. Reject failures caused by setup or by a different
  snapshot. Merge findings that share a root cause.
- Report verified findings by impact. Include the trigger, consequence, location,
  command, and relevant output. List material source-backed concerns whose checks
  could not run under verification limits, with the missing proof. Say “no
  verified findings” when appropriate and record which reviews and checks ran.
- If the target changed, refresh the affected review and checks before making
  claims about the current target. For a requested recheck of known fixes, reuse
  the original reviewer when available and review those fixes and their effects.
  Start a new broad pass only on request or for a materially different target.

## Example invocations

- `$adversarial-review staged`
- `$adversarial-review PR #105, focus on retries and shutdown`
- `$adversarial-review recheck the two fixes in the staged package`
- `$guided-review auto $adversarial-review with AGY`
