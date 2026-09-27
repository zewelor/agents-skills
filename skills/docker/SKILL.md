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
2. Pick the smallest viable runtime using [Minimal Non-Root Runtimes](#minimal-non-root-runtimes). Start truly static binaries with `scratch` and required runtime data; expand only for demonstrated needs.
3. Choose variable lifetime: use `ARG` for build-only versions, source revisions, toolchain paths, and compiler flags (including across later `RUN` instructions in the same stage); use `ENV` for values intentionally kept in the image or the build-stage environment, such as `PATH`. Re-declare global `ARG` after `FROM` when needed. Pass credentials through BuildKit secret or SSH mounts, never `ARG` or `ENV`.
4. Apply layer-cache hygiene: copy lockfiles before source, set `BUNDLE_PATH` outside the app dir for Ruby, use `--mount=type=cache` only when there are external dependencies.
5. If Compose is in scope, apply compatible runtime hardening from the orchestration section and select `build.target` when needed.
6. Apply per-stage cleanup in the same RUN: `apt-get clean && rm -rf /var/lib/apt/lists/*`; `npm cache clean --force`; `rm -rf /usr/share/doc /usr/share/man` before the runtime stage.

Check checksum and shell-utility flags in the actual build stage: Alpine's
BusyBox tools do not necessarily accept GNU long options (for example, use
`sha256sum -c` for a pinned checksum file rather than assuming `--check --strict`).
When inspecting optional Compose tools, include their profile in the resolved
configuration; absence from the default profile is not proof the service is missing.

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

Minimize production runtime contents. Use this preference order within the
application's actual linking/runtime requirements; skip incompatible choices.
Expand only for a demonstrated requirement or a justified maintenance/provenance
need. Treat this as a contents preference, not a universal security ranking:

1. For a truly static binary, start with `scratch`, the binary, and only required
   runtime data. Copy trusted CA certificates for HTTPS using system trust;
   declare a numeric non-root `USER`, such as `65532:65532`, and an exec-form
   `ENTRYPOINT`. Verify static linking rather than inferring it from the language;
   use `CGO_ENABLED=0` for Go when the application supports it.
2. Before changing the base, add a missing data file or writable directory when
   that is sufficient. Include timezone data only for named-zone conversion or
   local-time behavior that needs it; UTC, timeouts, and unchanged timestamp
   strings do not require it. For Go, consider embedding standard `time/tzdata`
   instead of copying zoneinfo files. Refresh copied CA/zoneinfo data through
   rebuilds; embedding tzdata requires rebuilding the binary to update it.
   Do not copy the builder's entire filesystem.
3. Consider a maintained static runtime, such as `dhi.io/static` or
   `gcr.io/distroless/static-debianX:nonroot`, when its supplied runtime files or
   maintenance/provenance benefits justify replacing the working scratch image.
   Compare actual contents and supported releases; do not assume one provider's
   static image is always smaller or safer. Keep static linking for these images;
   moving to a static base does not resolve a missing dynamic loader/library.
4. For dynamic linking, select the smallest maintained nonroot runtime providing
   the required loader and libraries, such as Distroless
   `base-debianX:nonroot` or `cc-debianX:nonroot`, or a matching DHI runtime. For interpreted apps, select a runtime for the language;
   a generic Distroless `base` alone does not supply Node.js or Python.
5. Use a minimal full-distribution runtime only when required capabilities cannot
   reasonably be supplied by the earlier choices. Keep shells, package managers,
   compilers, and debug utilities out of production unless the workload needs them.

Treat Docker Hardened Images as a provider choice at the appropriate step,
including `static`, rather than a larger final rung or a guarantee of greater
security. Evaluate signed SBOM/provenance, update policy, registry authentication,
and actual runtime contents alongside attack surface. Do not treat base-image
attestations as proof of the final build or copied binary. Pin external bases by
digest and deliberately refresh them; neither a minimal base nor DHI fixes
vulnerabilities in the copied binary or its compiled dependencies.

Validate the resulting image through realistic runtime scenarios covering the
application's actual needs: HTTPS trust, DNS resolution, nonroot permissions,
writable paths, and named timezones when used. Record the missing capability or
maintenance/provenance rationale before changing the base. Do not add a shell
solely to make production debugging easier.

Consult the [DHI runtime guidance](https://docs.docker.com/dhi/how-to/use/) and
[Distroless image catalog](https://github.com/GoogleContainerTools/distroless)
for supported variants and their contents.

For Ruby, use the `-distroless` variant from the `ghcr.io/zewelor/ruby` registry;
match the build image's Debian release.

Use the selected image's nonroot user (UID 65532 for Google Distroless `nonroot`)
or an explicit numeric UID/GID. Keep application code and dependencies
root-owned and readable/executable by that user; grant write ownership only
to paths the application must modify. Create or mount those paths with the
required permissions, including when using a read-only root filesystem.

Use external HTTP/TCP/gRPC probes where the orchestrator supports them, or
exec-form checks using an existing application healthcheck command. Docker
`HEALTHCHECK`, ECS container health checks, and Kubernetes exec probes run
inside the container and require the invoked executable there. Do not add a
shell or curl solely for a check; scratch and distroless can use an existing
application executable without a shell. Omit checks that do not fit the workload.

## Non-Root User Creation (when distroless is not viable)

Use the base image's suitable nonroot user when available. Otherwise declare a
numeric UID/GID; create passwd/group entries only when the application needs
user lookup or a home directory. Use the distribution's user-creation tools in
the build stage when available, keeping them out of a minimal runtime.

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

In distroless, copy `/bundle` and `/app` from the builder with read/execute
permissions for UID 65532 and run as `USER nonroot`. Keep code and gems
root-owned; provide separately writable paths only where the app needs them.

## Debian Version Alignment

For dynamically linked binaries and native extensions, verify target
architecture, libc (glibc versus musl), loader, and library ABI compatibility.
Prefer matching Debian releases for Debian build/runtime stages to reduce ABI
mismatches; verify required libraries rather than assuming the suite alone
is sufficient. Select explicit supported suite/version tags and pin digests.

Do not require matching distributions for a truly static binary without external
ABI dependencies. An Alpine Go builder with `CGO_ENABLED=0` can target scratch
or a compatible static runtime; validate the resulting artifact and image.

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
