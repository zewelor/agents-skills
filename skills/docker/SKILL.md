---
name: docker
description: Build or troubleshoot Docker images and configure container or Compose runtime. Route initial Dockerization, broader Compose workflows, Docker Agent, and Docker Sandboxes to Docker's official skills. Skip routine project commands and CI-only workflow changes.
---

# Docker Builds and Container Runtime

Keep image-hardening recommendations focused on production images. Disable
runtime networking only when the workload needs no network access, including
for local development and one-off tasks.

Keep the scope limited to Dockerfile structure, build context, BuildKit behavior,
image contents, runtime hardening, and Compose. Delegate CI trust boundaries,
permissions, credentials, action references, and cache-backend orchestration to a
GitHub Actions-specific skill.

For a task this skill does not cover, point to the relevant skill in Docker's
[official catalog](https://github.com/docker/skills#skills):
`docker-project-foundations` for initial containerization,
`docker-compose-patterns` for service wiring and development workflows,
`docker-build-strategies` for broader build guidance, or the Docker Agent and
Docker Sandboxes skills for those products. Load an official skill if it is
installed; otherwise consult its published guidance and link it in the answer.

## Workflow

For runtime changes, identify the effective Docker endpoint, accounting for
context, environment, and CLI overrides. Confirm daemon mode with `docker info`;
use its server security options to identify rootless, not the context name or
CLI user's UID. Check versions and feature support only where relevant.
If the target is unavailable or the task is image-only, report runtime assumptions
and unverified checks.

Match the work to the requested scope:

- For a single container launch from an existing image, apply only relevant
  runtime settings: network needs, mounts, user permissions, and compatible
  security/resource limits. Follow [Runtime Network Isolation](references/runtime.md#runtime-network-isolation).
  Do not add an image rebuild, change the base image, or redesign Compose
  unless required by the task.
- For Compose runtime configuration, apply relevant network and
  [orchestration settings](references/runtime.md#orchestration-security-hardening)
  to the affected services. Preserve the image build unless the
  requested change requires it.
  After completing the Compose changes, render the effective model using the
  applicable files, environment, and profiles. Inspect affected services and
  inherited settings; compare before and after only for refactors intended to
  preserve behavior. Filter the rendered model before printing it so resolved secrets stay out of logs and reports.
  Verify `!reset` in the rendered model, especially with YAML anchors or `extends`;
  do not infer its effect from source.
  Reuse shared settings only when their effective values and purposes match;
  preserve service-specific isolation and list-merge semantics.
  Verify required runtime guarantees that rendering cannot prove, such as startup
  or no-build behavior, in an isolated project. Before starting it, check the
  resolved mounts and published ports. Use disposable storage for writable data
  and avoid port conflicts with live services. Exercise failure cases only when
  needed to prove the guarantee. Do not build images solely for verification or
  modify live services.
- For user, bind-mount, Compose isolation or CPU/memory limit changes, follow [runtime guidance](references/runtime.md); verify required resource limits are enforced, not merely accepted in configuration.
- For Dockerfile stages, build context or `.dockerignore`, caching, platform builds, or base-image registry migrations, follow the [image workflow](references/build.md). For base image, runtime libraries or runtime user selection, consult [image runtime choices](references/image-runtime.md).
