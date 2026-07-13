# Read-Only Home Assistant Audit

Use this audit for a new instance or after a major HA upgrade. Do not implement
findings during the audit.

## Establish evidence

1. Verify deployment/runtime health, HA version, target, local Git state, and
   active-config Git state.
2. Run the documented production `check_config`. If both sources are Git
   worktrees, compare tracked configuration hashes to identify real drift.
3. Inspect repository YAML, Pyscript/AppDaemon, blueprints, shell commands, and
   documentation.
4. Inspect runtime logs, states, config entries, helpers, registries,
   dashboards, Repairs, and HACS read-only.

Prefer live state over assumptions and explain disagreement between sources.
Do not infer that an unavailable device is faulty without evidence.

## Review focus

- Prefer native triggers, conditions, helpers, targets, and selectors where
  they preserve exact semantics; flag unstable device or registry IDs.
- Keep templates needed for dynamic data or genuinely derived state; flag
  templates replaced cleanly by native behavior.
- Check automation concurrency/mode, waits, deprecated constructs, startup
  ordering, async I/O, unavailable inputs, task overlap, and exception paths.
- Use redacted saved traces for suspicious automation, script, and blueprint
  behavior; record which real trigger paths remain untested.
- Confirm REST/external-data failures cannot cause template errors, stale
  derived state, or falsely healthy output.
- Separate expected custom-integration warnings from actionable fresh errors.
- Group `unknown`/`unavailable` entities by integration and verify intentional
  offline devices with the owner.
- Map HACS `restart_required` Repairs to installed repository/version and
  distinguish current requirements from stale history. Never dismiss Repairs.
- Record confirmed backup and operational choices as accepted design decisions.
- Identify safe opportunities unlocked by the installed HA version using
  current official documentation.

## Report

Return:

1. verified healthy state with exact evidence;
2. P0/P1/P2 findings with impact, evidence, confidence, and smallest safe fix;
3. intentional/offline items and stale informational records;
4. version-specific upgrade opportunities;
5. tests still requiring real events or threshold crossings.

Ask the user to select or approve findings before changing anything.
