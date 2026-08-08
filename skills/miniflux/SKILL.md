---
name: miniflux
description: "Read a Miniflux account safely through its REST API. Use when the user asks to inspect unread news, entries, categories, category counters, or a specific saved entry and MINIFLUX_URL plus MINIFLUX_API_KEY are available. This skill is strictly read-only: never mark entries read, create, update, refresh, import, or delete Miniflux resources."
---

# Miniflux Reader

Use the bundled CLI for every request. It only issues `GET` requests, so it
cannot modify Miniflux state.

## Setup

Require both environment variables without printing their values:

- `MINIFLUX_URL`: the Miniflux instance root, without `/v1`.
- `MINIFLUX_API_KEY`: an API key created in Miniflux Settings → API Keys.

Require `curl` and `jq`. The CLI uses `jq` to return a compact, safe listing
without article bodies or feed credentials.

## API reference

Consult the [official Miniflux API reference](https://miniflux.app/docs/api.html)
before adding an operation or diagnosing an unexpected response. Preserve the
read-only boundary unless the user explicitly authorizes a state change.

## Read operations

Run the CLI from this skill directory or with its absolute path:

```bash
scripts/miniflux-read categories
scripts/miniflux-read feeds
scripts/miniflux-read feeds 42
scripts/miniflux-read counters
scripts/miniflux-read unread 20
scripts/miniflux-read category 42 20
scripts/miniflux-read starred 20
scripts/miniflux-read search 'Kubernetes' 20
scripts/miniflux-read entry 888
```

- Run `categories` to return every category with its feed and unread counts.
- Run `feeds [category-id]` to return feeds globally or in one category.
- Run `counters` to return read and unread counts keyed by feed ID.
- Run `unread [limit]` to return the newest unread entries; use default `20`
  and maximum `100`.
- Run `category <id> [limit]` to return unread entries in one category.
- Run `starred [limit]` to return bookmarked entries.
- Run `search <text> [limit]` to search saved entries.
- Run `entry <id>` to return one entry, including feed and category metadata.

Format the compact queue further when useful:

```bash
scripts/miniflux-read unread 20 | jq -r '.entries[] | [.id, .published_at, .feed.title, .title, .url] | @tsv'
```

## Safety boundary

- Use no HTTP method other than `GET`.
- Do not open the Miniflux web UI to inspect entries: UI behavior can alter read
  state depending on its settings.
- Do not call `fetch-content` with `update_content=true`, and do not call any
  endpoint named `refresh`, `mark-all-as-read`, `bookmark`, `save`, `import`,
  `flush`, `create`, `update`, or `delete`.
- Report API errors without echoing the API key. Ask before widening this skill
  beyond read-only access.
