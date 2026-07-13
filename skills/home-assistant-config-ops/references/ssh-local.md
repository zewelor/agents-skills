# SSH and Local Operations

## SSH

Use only the host alias recorded in `.deployment_info`. Confirm the target,
HA version, config path, runtime status, logs, and Git state through read-only
one-shot `ssh` commands before any delivery.

For a Git-managed configuration, follow the clean-worktree, saved-revision,
fast-forward, production `check_config`, rollback-on-failure, and approved
restart sequence in [change-delivery.md](change-delivery.md). Run each step
through explicit one-shot `ssh` commands. Use `scp` only when file copying is
explicitly approved. Never guess a host, service, container, Compose project,
or restart command.

## Local

Operate from the runtime directory recorded in `.deployment_info`, using its
direct, Docker, or Compose runtime type. Confirm HA version, runtime status,
logs, config path, and Git state read-only before delivery.

Apply the same clean-worktree, saved-revision, fast-forward, production
`check_config`, rollback-on-failure, and approved reload/restart sequence. Do
not assume a Compose service name or that the repository checkout is the live
configuration directory.

For either method, report missing commands or contradictory runtime facts as an
operational documentation gap instead of guessing an alternate topology.
