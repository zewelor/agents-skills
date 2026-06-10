---
name: docker
description: Hardened multi-stage Docker patterns: distroless non-root runtimes, Debian version alignment between build and runtime, secure compose manifests, BuildKit cache mounts, GitHub Actions multi-arch builds, .dockerignore hygiene, and the preferred Ruby/Bundler base image (ghcr.io/zewelor/ruby). Trigger on: 'Dockerfile', 'compose.yaml', 'docker-compose', 'distroless', 'hardening', 'read_only', 'cap_drop', 'HEALTHCHECK', 'healthcheck', 'buildx', 'multi-arch', 'linux/arm64', '.dockerignore', or when optimizing container builds/CI caches.
---

# Hardened Multi-Stage Docker Builds

Apply to production images, not local dev. See section headers below for the full scope.

## Workflow

When this skill triggers:

1. Identify the project language/runtime (Go, Node, Python, Ruby, or other). Pick the matching `deps` pattern below.
2. Pick the runtime base image: distroless `nonroot` is preferred. Fall back to creating a non-root user only if distroless is not viable.
3. Apply layer-cache hygiene: copy lockfiles before source, set `BUNDLE_PATH` outside the app dir for Ruby, use `--mount=type=cache` only when there are external dependencies.
4. For multi-arch in GitHub Actions, use `docker/setup-buildx-action` and `docker/build-push-action` (no standalone `docker buildx create` step needed).
5. Harden compose: `read_only`, `cap_drop: ALL`, `no-new-privileges`, custom networks with `internal: true` for backend, `deploy.resources.limits` + `restart_policy`, `build.target` for stage selection.
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

## Multi-Architecture Builds (GitHub Actions)

Multi-arch should be handled inside the GitHub Actions workflow, not as a standalone `docker buildx create` step. `docker/setup-buildx-action` provisions buildx and QEMU transparently.

Actions are referenced without pinned versions - update them as the upstream releases evolve:

```yaml
- uses: docker/setup-buildx-action
  with:
    platforms: linux/amd64,linux/arm64
- uses: docker/build-push-action
  with:
    context: .
    platforms: linux/amd64,linux/arm64
    push: true
    tags: ghcr.io/${{ github.repository }}:${{ github.sha }}
    cache-from: type=gha
    cache-to: type=gha,mode=max
```

In the Dockerfile, declare `ARG TARGETPLATFORM` when arch-specific binaries are needed (e.g., different base images for amd64 vs arm64).

## Distroless Non-Root Runtimes

Production containers should prefer Google Distroless bases over full OSes (Debian, Ubuntu, Alpine) to reduce attack surface.

- Static binaries (Go, Rust): `gcr.io/distroless/static-debianX:nonroot`.
- Dynamic binaries or interpreted apps (Node.js, Python): `gcr.io/distroless/base-debianX:nonroot` or language-specific distroless images.
- Static distroless runtimes have no dynamic linker. Static linking is required: `CGO_ENABLED=0` for Go, static musl/glibc targets for Rust.
- For Ruby, use the `-distroless` variant from the `ghcr.io/zewelor/ruby` registry; it matches the build image's Debian release automatically.

Distroless uses UID 65532 as `nonroot`. Chown the bundle to 65532:65532 before `COPY --from=builder` and run as `USER nonroot`.

Skip `HEALTHCHECK` in distroless (no `curl`/`wget`/`nc` available); rely on orchestrator-level probes (Kubernetes `livenessProbe`/`readinessProbe`, ECS `healthCheck`) which run from outside the container. Add a `HEALTHCHECK` directive only when the runtime image is not distroless (slim or alpine with shell utilities).

## Non-Root User Creation (when distroless is not viable)

When distroless is not an option (alpine with musl, slim Debian with shell needed, scratch without a user), create a non-root user explicitly. Always use a numeric UID, never a name, so the same image works across distroless-style base layers.

Debian / Ubuntu:

```dockerfile
RUN groupadd -r -g 1001 app && \
    useradd -r -u 1001 -g app -d /nonexistent -s /sbin/nologin app
USER 1001
```

Alpine:

```dockerfile
RUN addgroup -g 1001 -S app && \
    adduser -S app -u 1001 -G app
USER 1001
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

## Orchestration Security Hardening

In `compose.yaml` and Kubernetes manifests, apply maximum sandboxing to prevent runtime escalations:

- `read_only: true` - read-only root filesystem; blocks installing malicious packages or altering static assets at runtime.
- `security_opt: ["no-new-privileges:true"]` - blocks `setuid`/`setgid` privilege escalation.
- `cap_drop: ["ALL"]` - drops all default kernel capabilities; restricts administrative syscalls.
- `network_mode: none` - for utilities, linters, formatters that need no external connectivity; blocks exfiltration and inbound.
- `user: "1001:1001"` - always declare explicit non-root UID/GID unless using a natively nonroot base (Distroless `nonroot`).

Defense in depth and reliability:

- Custom networks: define separate `frontend` and `backend` networks. Mark backend-only services with `internal: true` so a compromised frontend cannot reach the DB directly.
- `deploy.resources.limits.cpus` and `memory` - prevent a runaway container from starving the host.
- `deploy.restart_policy.condition: on-failure` with `max_attempts: 3` - default resilience against crashes.
- `build.target: <stage>` - select a specific multi-stage target (e.g., `live`, `distroless`, `dev`) per environment instead of building the whole Dockerfile.
- For runtime secrets, prefer `*_FILE` env vars (e.g., `POSTGRES_PASSWORD_FILE: /run/secrets/db_password`) backed by Docker secrets or Kubernetes `Secret` volumes - never `ENV` literals.
