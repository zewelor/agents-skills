---
name: software-engineering
description: Apply focused engineering practices when implementing, fixing, or refactoring software. Use when selected for a project or explicitly requested; skip routine documentation and configuration-only changes.
---

# Software Engineering

Work within the user's scope and existing project conventions. Perform commits,
pushes, and other delivery actions only within the user's authorization.

## Keep the change focused

- Implement the smallest complete change that satisfies current requirements.
  Tie each new abstraction, configuration option, dependency, or compatibility
  path to a current need. Keep small local behavior together until separation
  clarifies an actual responsibility.
- Reuse existing validation, calculations, and metadata as sources of truth;
  derive dependent representations rather than maintaining parallel copies.
  Share equivalent behavior where it improves clarity; preserve distinct contracts.
- Establish the domain terms and data representation before writing the logic.
  Use types and structures to rule out invalid states where practical.
- When a new requirement multiplies special cases, reconsider the domain model
  and choose a simpler representation within the agreed scope.

## Make state and failures explicit

- Parse and validate external data once at its entry boundary. Keep business
  decisions separate from I/O so they can be checked independently.
- Give independent operations separate mutable state before adding locks.
  When sharing is necessary, define and enforce write ownership; prefer a
  single writer where the model permits it.
- Make operations safe to repeat after partial failure where retries or
  idempotency are part of the contract.
- On invalid state or unexpected errors, stop the affected operation and report
  the error unless the contract defines recovery. Preserve required fallbacks
  and other recovery with explicit triggers and outcomes. Never silently turn
  failed work or missing required data into an empty or default success result.

## Implement and verify

- Work in small, verifiable slices.
- For bugs, reproduce the failure and fix its cause; avoid guards that only
  conceal it.
- When successive fixes based on the same assumption fail, state that assumption
  and check it against evidence before attempting another patch.
- For behavior changes needing new coverage, write a test, run it against the
  unchanged code, and confirm failure for the expected reason before implementing
  the change. Apply the smallest fix that passes it. If a meaningful test is
  impractical, report the gap instead of adding a misleading test.
- For refactoring, establish the behavior to preserve and verify it afterward.
  Test observable contracts and realistic failures, not implementation details.
- For flows whose result is not established by focused tests, run representative
  inputs through the actual user path and inspect the relevant outputs within
  the authorized validation scope.
- Use complexity, duplication, coverage, or mutation analysis when it addresses
  a concrete risk. Review findings in context; do not optimize a score or add a
  tool merely to satisfy a universal threshold.
- Finish with a simplification pass over the changed area; remove unnecessary
  machinery introduced by the change while retaining required behavior and recovery.
- Report the result, checks performed, and gaps.
  State what was actually exercised; leave wider runtime claims unverified.
