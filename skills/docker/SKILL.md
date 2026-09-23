---
name: docker
description: Build or troubleshoot Docker images and configure container or Compose runtime. Skip routine execution of existing project commands and CI-only workflow changes.
---

# Docker Builds and Container Runtime

Keep image-hardening recommendations focused on production images. Disable
runtime networking only when the workload needs no network access, including
for local development and one-off tasks.

Keep the scope limited to Dockerfile structure, build context, BuildKit behavior,
image contents, runtime hardening, and Compose. Delegate CI trust boundaries,
permissions, credentials, action references, and cache-backend orchestration to a
GitHub Actions-specific skill.

## Workflow

Match the work to the requested scope:

- For a single container launch from an existing image, apply only relevant
  runtime settings: network needs, mounts, user permissions, and compatible
  security/resource limits. Follow [Runtime Network Isolation](#runtime-network-isolation).
  Do not add an image rebuild, change the base image, or redesign Compose
  unless required by the task.
- For Compose runtime configuration, apply relevant network and orchestration
  settings to the affected services. Preserve the image build unless the
  requested change requires it.
- For Dockerfile or image-build work, follow the image workflow below and
  consult the relevant build sections.

### Image workflow

1. Identify the project language/runtime (Go, Node, Python, Ruby, or other). Pick the matching `deps` pattern below.
2. Pick the smallest viable runtime: scratch for a truly static binary, distroless `nonroot` when runtime files are needed, or an explicit non-root user otherwise.
3. Choose variable lifetime: use `ARG` for build-only versions, source revisions, toolchain paths, and compiler flags (including across later `RUN` instructions in the same stage); use `ENV` for values intentionally kept in the image or the build-stage environment, such as `PATH`. Re-declare global `ARG` after `FROM` when needed. Pass credentials through BuildKit secret or SSH mounts, never `ARG` or `ENV`.
4. Apply layer-cache hygiene: copy lockfiles before source, set `BUNDLE_PATH` outside the app dir for Ruby, use `--mount=type=cache` only when there are external dependencies.
5. If Compose is in scope, apply compatible runtime hardening from the orchestration section and select `build.target` when needed.
6. Apply per-stage cleanup in the same RUN: `apt-get clean && rm -rf /var/lib/apt/lists/*`; `npm cache clean --force`; `rm -rf /usr/share/doc /usr/share/man` before the runtime stage.

## Multi-Stage Dockerfile Architecture

All applications should use multi-stage builds to isolate the toolchain, dependencies, and tests from the production runtime.

Stage lifecycle:

- `base` - runtime/SDK environment with host platform variables.
- `deps` - resolve packages before copying source, to leverage layer caching.
  - Go: `COPY go.mod ./` + `RUN go mod download`
  - Node.js: `COPY package.json package-lock.json ./` + `RUN npm ci`
  - Python: `COPY requirements.txt ./` + `RUN pip install -r requirements.txt`
  - Ruby: `COPY Gemfile Gemfile.lock ./` + `RUN bundle install -j$(nproc) --retry 3` (with `BUNDLE_PATH=/bundle` set in the base stage)
- `validate` - tests, linters, type-checks in an isolated layer.
- `build` - compile, bundle, or minify (`go build`, `npm run build`, `cargo build`).
- `runtime` - clean stage with only production artifacts copied from `build`.

Source changes invalidate only downstream stages; downloaded modules stay cached. Avoid copying volatile source code (`/src`, `/app/src`, general code files) before or during `deps`.

## Build Context Hygiene (.dockerignore)

A missing or thin `.dockerignore` sends the entire repo to the Docker daemon on every build. Three separate problems:

- Build time: multi-GB context over network for every `docker build`.
- Secret leakage: `.env`, `*.pem`, `id_rsa` get baked into image layers, visible in `docker history` even after `rm`.
- Cache invalidation: any timestamp change in the context invalidates layers.

Minimum `.dockerignore` for most projects:

```
.git
.gitignore
.env*
*.pem
*.key
node_modules
__pycache__
*.pyc
.vscode
.idea
*.log
Dockerfile
README.md
docker-compose*.yml
```

Adjust per project (e.g., add `target/` for Rust, `dist/` for Node, `vendor/bundle` for Ruby). The principle: exclude anything not explicitly `COPY`'d.

## Build Cache Mounts (BuildKit)

For compiled languages with heavy dependency graphs (Go, Rust, C/C++), use `--mount=type=cache` to persist the package registry and build artifact cache between Docker builds. Layer cache is empty on a fresh build context, so cache mounts help only when source changes trigger rebuilds of the same module graph.

Skip cache mounts when there are no external dependencies or the build runs in seconds. Separate `COPY` of lockfiles before source already gives correct layer invalidation; the explicit `--mount=...` flags add noise without measurable speedup.

```dockerfile
# Go: $GOMODCACHE and $GOCACHE
RUN --mount=type=cache,target=/go/pkg/mod \
    --mount=type=cache,target=/root/.cache/go-build \
    go mod download

# Rust: $CARGO_HOME/registry and Cargo target dir
# Note: Since the cache mount is unmounted after this RUN step, you must copy the compiled binary out of the target folder to another path (e.g., /app/app-binary) within the same RUN step so it is accessible to subsequent stages.
RUN --mount=type=cache,target=/usr/local/cargo/registry \
    --mount=type=cache,target=/app/target \
    cargo build --release && \
    cp target/release/app-binary /app/app-binary
```

Requires BuildKit (Docker 23+).

## Cross-Platform Builds

Keep compilation on the build platform when the toolchain supports native
cross-compilation. Use `FROM --platform=$BUILDPLATFORM`, declare only the
automatic platform arguments the Dockerfile consumes (`TARGETOS`,
`TARGETARCH`, or `TARGETPLATFORM`), and emit the target artifact explicitly.

Require QEMU/binfmt only when a build stage executes target-architecture
binaries. Do not add emulation for a Go build that runs on `$BUILDPLATFORM` and
cross-compiles with `GOOS` and `GOARCH`. Buildx can use an existing binfmt
installation, but setting up a builder does not itself install QEMU.

Treat base-image freshness and layer caching as separate controls: pulling
referenced images does not imply a no-cache build.

## Minimal Non-Root Runtimes

Prefer scratch or Google Distroless over a full OS runtime when the application permits it.

- Truly static binaries: scratch with only the binary and required runtime data such as CA certificates; declare a numeric `USER` such as `65532:65532`.
- Static binaries (Go, Rust): `gcr.io/distroless/static-debianX:nonroot`.
- Dynamic binaries or interpreted apps (Node.js, Python): `gcr.io/distroless/base-debianX:nonroot` or language-specific distroless images.
- Static distroless runtimes have no dynamic linker. Static linking is required: `CGO_ENABLED=0` for Go, static musl/glibc targets for Rust.
- For Ruby, use the `-distroless` variant from the `ghcr.io/zewelor/ruby` registry; it matches the build image's Debian release automatically.

Distroless uses UID 65532 as `nonroot`. Chown the bundle to 65532:65532 before `COPY --from=builder` and run as `USER nonroot`.

Skip `HEALTHCHECK` in distroless (no `curl`/`wget`/`nc` available); rely on orchestrator-level probes (Kubernetes `livenessProbe`/`readinessProbe`, ECS `healthCheck`) which run from outside the container. Add a `HEALTHCHECK` directive only when the runtime image is not distroless (slim or alpine with shell utilities).

## Non-Root User Creation (when distroless is not viable)

When scratch or distroless is not viable and the runtime needs a full OS, create a non-root user explicitly. Use a numeric UID and GID for custom users so the image works consistently across runtimes; official distroless `nonroot` images are the named-user exception.

Debian / Ubuntu:

```dockerfile
RUN groupadd -r -g 1001 app && \
    useradd -r -u 1001 -g app -d /nonexistent -s /sbin/nologin app
USER 1001:1001
```

Alpine:

```dockerfile
RUN addgroup -g 1001 -S app && \
    adduser -S app -u 1001 -G app
USER 1001:1001
```

Match this UID with the corresponding `user: "1001:1001"` in compose to avoid bind-mount permission mismatches between dev and prod.

## Ruby + Bundler

Base images from the `ghcr.io/zewelor/ruby` registry: `-slim` variant for the build stage, matching `-distroless` variant for the runtime stage. Pin the tag in the Dockerfile to the Ruby version targeted.

Critical settings:

- `BUNDLE_PATH=/bundle` - install gems outside the app dir; volume mounts of source do not overwrite the bundle.
- `BUNDLE_WITHOUT="development:test"` in the production build stage - skip dev/test groups.
- `BUNDLE_DEPLOYMENT="1"` in the runtime stage - lock gem versions; bundler must not upgrade at start.
- `RUBYOPT='--disable-did_you_mean'` in the runtime stage - smaller, faster startup (skips the did_you_mean gem).
- `bundle install "-j$(nproc)" --retry 3` - parallel install with retries.

Native extensions (e.g., `psych` for YAML, `nokogiri`) require build tools and headers at the `deps` stage but not at runtime. Pass them via a `DEV_PACKAGES` build arg (e.g., `build-essential libyaml-dev`) and exclude them from the runtime base.

In distroless: in the builder stage, `chown -R 65532:65532 /bundle /app`. Then in the distroless stage, `COPY --from=builder /bundle /bundle` and `COPY --from=builder /app /app`, and run as `USER nonroot` (UID 65532).

## Debian Version Alignment

Build SDK/compiler base image and Distroless runtime image should target the exact same Debian release. Mismatches cause glibc errors and OS drift.

- Avoid rolling or generic tags (`golang:latest`, `node:22`, `python:3.12`). Declare the suite name explicitly (e.g., `-trixie` for Debian 13) to match build and runtime.
- Debian 13 / Trixie: build `golang:1.26-trixie` / `node:22-trixie`; runtime `gcr.io/distroless/static-debian13:nonroot` / `base-debian13:nonroot`.

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

In `compose.yaml` and Kubernetes manifests, apply maximum sandboxing to prevent runtime escalations:

- `read_only: true` - read-only root filesystem; blocks installing malicious packages or altering static assets at runtime.
- `security_opt: ["no-new-privileges:true"]` - blocks `setuid`/`setgid` privilege escalation.
- `cap_drop: ["ALL"]` - drops all default kernel capabilities; restricts administrative syscalls.
- `user: "1001:1001"` - always declare explicit non-root UID/GID unless using a natively nonroot base (Distroless `nonroot`).

Defense in depth and reliability:

- Custom networks: define separate `frontend` and `backend` networks. Mark backend-only services with `internal: true` so a compromised frontend cannot reach the DB directly.
- `deploy.resources.limits.cpus` and `memory` - prevent a runaway container from starving the host.
- `deploy.restart_policy.condition: on-failure` with `max_attempts: 3` - default resilience against crashes.
- `build.target: <stage>` - select a specific multi-stage target (e.g., `live`, `distroless`, `dev`) per environment instead of building the whole Dockerfile.
- For runtime secrets, prefer `*_FILE` env vars (e.g., `POSTGRES_PASSWORD_FILE: /run/secrets/db_password`) backed by Docker secrets or Kubernetes `Secret` volumes - never `ENV` literals.
