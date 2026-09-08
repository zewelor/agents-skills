# Approved Change Delivery

## Normal flow

Reuse explicit approvals already given in the conversation for the same
target, actions, and change scope. Allow one approval to cover commit, push,
production transfer, restart, and rollback when those actions were included.
Ask only for missing authorization or material changes to the approved scope
or effects. Do not infer production authority from an edit or audit request.

1. Edit the repository, review the diff, and run repository-local static
   checks. Run the bundled Pyscript validator when `pyscript/` exists.
2. Present the diff and checks. Commit or push only with approval covering
   those actions; request it only if not already given.
3. Confirm existing approval covers production delivery and the intended
   reload/restart; ask only for uncovered actions. Verify the production
   config worktree is clean and record its current revision.
4. Transfer only the approved revision using the method in `.deployment_info`.
   For Git, fetch and fast-forward the clean production worktree.
5. After changed files exist in production, run HA `check_config` against that
   production config path.
6. On validation failure, do not restart. Restore the recorded revision if
   rollback is already approved; otherwise request approval. Report the
   validation error.
7. On success, perform only the approved reload/restart. Verify readiness, HA
   version, fresh startup logs, and affected behavior.

## Dirty production fallback

If the production worktree is dirty before normal delivery, stop and report
the exact non-sensitive diff. Do not overwrite it or continue normal transfer.

A recorded fallback that stages, commits, or pushes production changes is
recovery for manual production edits, not routine delivery. Use it only after
the user explicitly approves the exact diff and all resulting Git actions.

## Operational gaps

If a command fails or reality contradicts the documented method, make the
smallest safe read-only diagnostic check and stop. Report:

- operation and target;
- redacted command/output evidence;
- expected versus actual result;
- missing or incorrect instruction;
- smallest proposed documentation or metadata correction.

Never turn undocumented trial-and-error into an implicit operational method.
