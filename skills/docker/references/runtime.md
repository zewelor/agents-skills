### Runtime users and bind mounts

- Prefer the image's non-root user; override it with Compose `user` only for
  required access or application behavior. This override does not change daemon mode.
- Before changing users or bind mounts, check paths and permissions on the daemon
  host (including remote or Desktop environments): ownership, traversal, groups,
  ACLs, and UID/GID mapping. In rootless, container UID 0 maps to the daemon's
  host user; nonzero UIDs map to subordinate IDs. In `userns-remap`, UID 0 also
  maps to a subordinate ID. Matching numeric host/container UIDs alone is insufficient.
- Allow `user: "0"` for verified rootless workloads needing that host user's
  files. Record the reason and verify application compatibility. Namespace root
  retains access to that user's mounted files; it is not host UID 0. Reassess
  this override before using rootful Docker or `userns-remap`.
- Verify required reads and traversal as the chosen process user. If writes are
  needed, test them and resulting host ownership in a disposable directory on
  the same mount. Use application tools when the image has no shell.
- Mount inputs read-only where possible. Preserve host permissions; do not default
  to recursive `chown`, broad `chmod`, or privileged mode to fix access failures.

For uncertain mappings, consult Docker's [UID/GID guidance](https://docs.docker.com/engine/security/rootless/uid-gid-mapping/).
For version-dependent networking, privileged port publishing, or resource limits,
check the relevant [rootless tips](https://docs.docker.com/engine/security/rootless/tips/)
and [limitations](https://docs.docker.com/engine/security/rootless/troubleshoot/).

## Runtime Network Isolation

Disable networking whenever the container workload needs no network access,
including utilities, linters, formatters, and offline tests:

- Use `docker run --network none ...` for CLI launches.
- Set `network_mode: "none"` on the service for `docker compose` or
  `docker-compose`, including one-off `run` commands. Omit the service's
  `networks` field when setting `network_mode`.
- Check whether the workload needs downloads, APIs, databases, communication
  with other containers, or inbound connections before disabling networking.
  Keep networking enabled only where needed; do not equate no internet access
  with no network access.

## Orchestration Security Hardening

Apply compatible hardening to the affected workload and verify required file
access and startup behavior. Use the following Compose settings; translate them
to the orchestrator's equivalent fields for Kubernetes rather than copying Compose keys:

- `read_only: true` - make the container root filesystem read-only. Check writable mounts separately.
- `security_opt: ["no-new-privileges:true"]` - blocks `setuid`/`setgid` privilege escalation.
- `cap_drop: ["ALL"]` - drops all default kernel capabilities; restricts administrative syscalls.
- `user` - keep the image's suitable user or choose a verified override through [Runtime users and bind mounts](#runtime-users-and-bind-mounts).

Defense in depth and reliability:

- Custom networks: connect services only to networks needed for communication; keep a frontend off the DB's network when it needs no direct DB access. Use `internal: true` for external isolation; services sharing that network can still communicate.
- `deploy.resources.limits.cpus` and `memory` - configure supported limits and verify they are enforced. For rootless Docker, check cgroup v2, the systemd driver, and delegation of the required controllers; `Cgroup Driver: none` means cgroup limits are ignored. Do not treat successful Compose parsing as proof of enforcement.
- Match restart policy to the service lifecycle. Enable retries for a one-off job or migration only when repeating it after partial failure is safe and intended.
- `build.target: <stage>` - select a specific multi-stage target (e.g., `live`, `distroless`, `dev`) per environment instead of building the whole Dockerfile.
- Mount runtime secrets and use the file interface the application or image entrypoint supports. Set a variable such as `POSTGRES_PASSWORD_FILE` only when the image reads it. Keep secret values out of Dockerfile `ENV` instructions.
