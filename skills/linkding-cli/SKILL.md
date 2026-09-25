---
name: linkding-cli
description: "Find and manage bookmarks and tags in a self-hosted Linkding instance with chickenzord/linkding-cli. Use for requests to search, list, inspect, save, edit, archive, unarchive, or delete Linkding bookmarks, check whether a URL is saved, or list and create tags."
---

# Linkding CLI

Use the `linkding` executable supplied by `github:chickenzord/linkding-cli`. These examples match version `0.1.0`. Its commands use singular `bookmark` and `tag`; do not confuse it with other tools named `linkding-cli` that use `bookmarks` and `tags`.

## Prepare

1. Run `linkding version` and `linkding --help` before relying on these examples. If the executable is outside `PATH`, try `mise exec -- linkding version` and prefix subsequent calls with `mise exec --`.
2. Require `LINKDING_URL` (instance base URL) and `LINKDING_TOKEN` (API token from Linkding Settings → Integrations). Check only whether they are set; never print the token, pass it as `--token`, include it in shell history, or write it into a skill or repository file. If either is absent, ask the user to provide it through the environment.
3. Use the environment for the instance URL. The `--url` flag on `bookmark check`, `create`, and `update` names the **bookmark URL**, so it can be confused with the global instance `--url` flag.
4. Read subcommand help for flags not shown here. Prefer the installed binary's help when it differs from this guide. Use the [upstream CLI README](https://github.com/chickenzord/linkding-cli) for broader reference.

## Read bookmarks and tags

Use `--json` for structured results; use `-q` only for one-item-per-line output. Quote URLs and search text.

```bash
linkding bookmark list --search 'golang' --limit 20 --json
linkding bookmark list --unread --limit 20 --offset 20 --json
linkding bookmark list --archived --json
linkding bookmark list --shared --json
linkding bookmark get 42 --json
linkding bookmark check --url 'https://example.com' --json
linkding tag list --search 'go' --limit 20 --json
linkding tag get 5 --json
```

Read bookmark list items from `.results[]`; use `.count` and `.next` to recognize more pages. Paginate with `--limit` and `--offset` when the request needs more than one page; do not treat a single page as the full collection. Use `bookmark check` for an exact URL lookup and suggested metadata or tags before saving it.

## Change bookmarks and tags

Match the user's requested fields and state. Check the URL before creating a bookmark: Linkding's API can update an existing bookmark when a URL is submitted again. Fetch an ID before changing or deleting it. Use `--dry-run` on supported write commands to inspect the intended operation, then run the command without it. Re-read the affected bookmark or tag afterward.

```bash
linkding bookmark create --url 'https://example.com' --title 'Example' --tags 'reference,tools' --dry-run --json
linkding bookmark create --url 'https://example.com' --title 'Example' --tags 'reference,tools' --json
linkding bookmark update 42 --title 'Better title' --dry-run --json
linkding bookmark update 42 --title 'Better title' --json
linkding bookmark archive 42 --json
linkding bookmark unarchive 42 --json
linkding tag create --name 'reference' --dry-run --json
linkding tag create --name 'reference' --json
linkding bookmark delete 42 --dry-run --json
linkding bookmark delete 42 --yes --json
```

Use `--yes` for deletion in a non-interactive agent session only after identifying the exact bookmark and confirming that deletion is requested. `bookmark update` sends only supplied fields; supplying `--tags` **replaces** the bookmark's tag set, so fetch existing tags first when the user asks to add or remove just one tag. Inspect `bookmark create --help` and `bookmark update --help` for optional description, notes, unread, shared, and archived fields rather than guessing their flags.

## Handle output and errors

- Keep `--json` output on stdout for parsing; treat stderr and exit status as diagnostics. Check the command's exit status before interpreting or piping its JSON.
- Interpret exit codes as `0` success, `1` general error, `2` usage or configuration error, `3` not found, `4` permission denied, and `5` conflict. In JSON mode, use the structured `error`, `message`, `input`, `suggestion`, and `retryable` fields when available.
- Report missing configuration, authentication, connectivity, and conflicts without exposing credentials. Retry only when the error is retryable; do not turn an uncertain write result into a duplicate request without checking current state.
