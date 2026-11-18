## Execution Selection

- Start with the repository's release unit and simplest sufficient flow. For one
  application, prefer native workflow triggers, verification jobs, and publication
  gated by `needs`. Publishing the fully verified revision on every qualifying
  main run is a valid simplicity tradeoff; explain that test/config changes may
  publish too. Distinguish latest successful state from every pushed tip or every
  commit within a push; pending replacement cannot satisfy an every-run contract.
  Split workflows for independently released components when their triggers and
  concurrency can be independent. Reuse verification through
  `workflow_call` when useful; moving conditions to another file is not simplification.
- Keep native exclusions for inputs outside the release unit. A skipped workflow
  does not replace a pending run; distinguish that from an admitted run that
  cancels verification or skips publication through a per-push image filter.
  Do not remove all path filters merely because pending replacement is possible.
- Match guarantees to the actual requirement. For a small project accepting
  latest-successful publication and explicit reruns, prefer native `needs` and
  concurrency. Add custom promotion scripts, ancestry checks or registry state
  only for a demonstrated stricter requirement; compare their ongoing cost with
  the accepted race. Do not add application-language tests solely for CI glue.
- Separate eligibility to verify, build an artifact, publish it, and deploy it.
  Successful verification is a prerequisite for publication, not evidence that
  the change requires a new release. Preserve intentional tag, manual, scheduled
  rebuild and per-commit release contracts; state any authorized policy change.
- Derive each artifact's inputs from its actual build: source, dependencies,
  embedded assets, generated inputs, Dockerfile stages, COPY and ignore rules.
  A test database, Compose fixture or CI tool update may require integration
  checks without requiring a production image. Documentation may be embedded;
  do not exclude it by filename alone. Treat independently deployed components
  separately, including their shared inputs.
- Inspect overlapping workflows and `push`/`pull_request` triggers. Prefer one
  verification per intended revision/event; preserve branch-before-PR checks
  when required by the repository or automation. Concurrency keyed by ref does
  not deduplicate a branch push and its PR merge ref.
- Choose the simplest mechanism that preserves these boundaries. Native path
  filters suit whole workflows; job conditions suit differing scopes or required
  checks that must report success. Check required-status behavior before filtering
  a workflow. Prefer existing helpers or documented tooling over custom diff logic.
- When comparing changes, verify the chosen tool's push, PR, initial-branch and
  manual/tag semantics. Cover multi-commit pushes, deletions and renames; unavailable
  comparison data must fail visibly, not silently skip required work. Keep source
  lists aligned with build inputs and avoid weakening tested-artifact guarantees.
- Evaluate selection together with concurrency and release state. A diff against
  the previous push does not include unpublished changes from a cancelled, failed,
  or replaced run. Even `cancel-in-progress: false` can replace a pending run.
  Cancel superseded verification only when its replacement still covers the full
  release unit. Use independent component triggers/concurrency or a verified
  successful-publication baseline when selective publication is required; do not
  add persisted tracking when publishing each qualifying run meets the task.
  Treat an already-started external publication separately: cancellation does not
  roll back side effects. Preserve intentional manual retry/recovery contracts.
- Before editing filters, record representative change/event cases and expected
  jobs: production input, test/fixture-only, docs/tooling-only, mixed changes,
  PR and main push, plus supported release events. Validate both required runs
  and required skips against the resulting configuration. Report local selection
  evidence separately from hosted runs or measured savings. Include sequences:
  runtime then tests-only, component A then B, pending replacement, cancelled or
  failed verification/publication, and rerun. Check which complete revision and
  components are ultimately published, not only each run's isolated predicate.
