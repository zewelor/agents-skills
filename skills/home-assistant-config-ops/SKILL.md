---
name: home-assistant-config-ops
description: Safely audit, validate, deploy, and troubleshoot a Home Assistant configuration across Kubernetes, SSH, or local runtimes. Use for read-only HA health/configuration audits, creating or verifying repo-local .deployment_info metadata, checking repository-to-runtime drift, validating YAML or Pyscript changes, copying configuration, reading runtime logs, delivering approved Git revisions, restarting or verifying HA, and documenting repeatable operational methods. Pair with a Home Assistant configuration best-practices skill for YAML, automation, script, helper, and dashboard design review.
---

# Home Assistant Config Ops

Use a small repo-local `.deployment_info` file for instance-specific facts and
this skill for reusable operational procedures. Treat the repository and the
active HA runtime as separate evidence sources.

## Establish scope and authority

1. Read the repository `AGENTS.md`, `.deployment_info`, and relevant local
   documentation before runtime access.
2. If `.deployment_info` is missing or incomplete, follow
   [deployment-bootstrap.md](references/deployment-bootstrap.md). Create it as
   a separate preparatory step, not as part of a read-only audit.
3. Start runtime investigation read-only. Do not edit `.storage`, expose
   secrets, call mutating services, copy files, restart HA, or deploy unless
   the user explicitly authorizes that action.
4. Never commit, push, open a pull request, tag, deploy, or restart solely
   because the user asked to edit or audit. Obtain explicit approval for each
   applicable action.
5. When instructions or access fail, perform only the smallest safe read-only
   check that distinguishes the cause. Promptly report the target, redacted
   evidence, expected and actual result, missing instruction, and smallest
   proposed correction. Do not silently invent a workaround.

## Route the task

- For a comprehensive inventory or post-upgrade review, follow
  [read-only-audit.md](references/read-only-audit.md). Also use the available
  Home Assistant best-practices skill.
- For an approved configuration change, follow
  [change-delivery.md](references/change-delivery.md).
- For Kubernetes commands, follow
  [kubernetes.md](references/kubernetes.md).
- For SSH or local runtime commands, follow
  [ssh-local.md](references/ssh-local.md).

Use current official Home Assistant or tool documentation for version-specific
syntax and API claims. Do not infer external API health from `check_config`.

## Validate repository changes

Run repository-specific checks first. For Pyscript syntax, run:

```bash
python3 .agents/skills/home-assistant-config-ops/scripts/validate_pyscript_syntax.py --repo-root .
```

The validator parses Python without importing or executing it. Home Assistant's
`hass --script check_config -c <config-path>` validates YAML/schema loading but
does not load Pyscript or prove integrations, dashboards, external APIs, or
automation behavior.

After an approved delivery, run `check_config` against the changed production
configuration before restart. Then verify runtime readiness, fresh logs, and
the affected entity or automation behavior.

## Protect sensitive and HA-managed state

Never read, print, copy, or commit `secrets.yaml`, `.storage/auth*`, tokens,
private keys, cookies, or credential-bearing config-entry values. Treat
UI-managed helpers, dashboards, config entries, registries, and Repairs as
HA-managed state; inspect them read-only and never edit `.storage` directly.
