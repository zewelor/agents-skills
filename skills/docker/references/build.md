# Image workflow

- [Multi-stage builds](#multi-stage-dockerfile-architecture)
- [Build context](#build-context-hygiene-dockerignore)
- [Build cache mounts](#build-cache-mounts-buildkit)
- [Cross-platform builds](#cross-platform-builds)

Prefer publisher-maintained GHCR images over Docker Hub when the required
version and target platforms are available; otherwise keep the current provider.
Verify the registry in official publisher documentation, avoid unofficial
mirrors, and pin the version and verified digest. When migrating registries,
preserve the version and update matching Renovate or Dependabot package rules.

For uv, copy `/uv` and `/uvx` from `ghcr.io/astral-sh/uv` into the build stage;
follow the [official Docker guide](https://docs.astral.sh/uv/guides/integration/docker/).

1. Identify the project language/runtime (Go, Node, Python, Ruby, or other). Pick the matching `deps` pattern below.
2. Pick the smallest viable runtime using [Minimal Non-Root Runtimes](image-runtime.md). Start truly static binaries with `scratch` and required runtime data; expand only for demonstrated needs.
3. Choose variable lifetime: use `ARG` for build-only versions, source revisions, toolchain paths, and compiler flags (including across later `RUN` instructions in the same stage); use `ENV` for values intentionally kept in the image or the build-stage environment, such as `PATH`. Re-declare global `ARG` after `FROM` when needed. Pass credentials through BuildKit secret or SSH mounts, never `ARG` or `ENV`. For automatic platform arguments, follow [Cross-Platform Builds](#cross-platform-builds).
4. Apply layer-cache hygiene: copy dependency manifests and lockfiles before source; set `BUNDLE_PATH` outside the app dir for Ruby. Add cache mounts when repeated downloads or compilation justify them.
5. If Compose is in scope, apply compatible runtime hardening from [Orchestration Security Hardening](runtime.md#orchestration-security-hardening) and select `build.target` when needed.
6. Clean non-mounted package caches in the install RUN and remove unneeded docs/man pages before the runtime stage. Preserve cache-mounted directories; follow [Build Cache Mounts](#build-cache-mounts-buildkit) for cached installs.

Check checksum and shell-utility flags in the actual build stage: Alpine's
BusyBox tools do not necessarily accept GNU long options (for example, use
`sha256sum -c` for a pinned checksum file rather than assuming `--check --strict`).
When inspecting optional Compose tools, include their profile in the resolved
configuration; absence from the default profile is not proof the service is missing.

## Multi-Stage Dockerfile Architecture

Use multi-stage builds when separating build/test tools from the production
runtime reduces its contents. Keep a single stage when no such separation is
needed; create only stages the project uses.

Select relevant stages from this lifecycle:

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
- Cache invalidation: changes to files used by `COPY`/`ADD` can invalidate downstream layers; changes to `mtime` alone do not.

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

Use cache mounts for expensive repeated downloads or compilation. Ordinary layer
cache skips a `RUN`; mounts reuse work when that instruction executes again.
Skip mount setup for fast steps where rebuild savings do not justify it.

- Keep builds correct with empty or evicted caches; write required artifacts
  outside cache mounts.
- For APT, keep update and install in one `RUN`; use `sharing=locked` on
  `/var/cache/apt` and `/var/lib/apt/lists`. For cached installs, remove hooks
  such as `docker-clean` that would clear the cache; do not clean the mounted
  directories.
- Inspect inherited `DEBIAN_FRONTEND` before adding it. When needed, scope
  `noninteractive` to the install command; `apt-get -y` handles APT confirmation,
  not debconf questions.
- Compare actual cold/warm executions before claiming speedups. Invalidate the
  target `RUN` with a changed input or `ARG`; `--no-cache` also resets cache
  mounts. Check CI persistence separately: `type=gha` does not preserve them.

For package-manager options and cache lifetime, consult [Docker cache guidance](https://docs.docker.com/build/cache/optimize/#use-cache-mounts).
For GitHub Actions cache behavior, consult [cache mount persistence](https://docs.docker.com/build/ci/github-actions/cache/#cache-mounts).

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
cross-compilation. Use `FROM --platform=$BUILDPLATFORM` and declare only the
automatic platform arguments the Dockerfile consumes, such as `TARGETOS`,
`TARGETARCH`, or `TARGETPLATFORM`, inside the build stage **without defaults**.
Do not assign values such as `ARG TARGETARCH=amd64` or `ARG TARGETOS=linux`:
these override BuildKit's target values and can put a binary for the wrong
architecture inside an otherwise correctly labeled image.

For a static Go build, inherit the requested platform explicitly:

```dockerfile
ARG TARGETOS
ARG TARGETARCH
RUN CGO_ENABLED=0 GOOS=$TARGETOS GOARCH=$TARGETARCH go build -o /out/app ./cmd/app
```

Follow [Docker's cross-compilation example](https://docs.docker.com/build/building/multi-platform/#cross-compilation)
for the complete build-stage pattern. When adding or changing cross-compilation,
verify an affected non-native artifact's architecture with `file`, `readelf`, or
an equivalent tool where available. A successful build or image platform label
alone does not prove the binary's architecture; report unavailable verification.
Keep this a one-off check unless an existing release contract or the user calls
for ongoing coverage. Do not add persistent ARM64 checks, multi-platform CI
matrices, or emulation solely because the Dockerfile supports cross-compilation.

Require QEMU/binfmt only when a build stage executes target-architecture
binaries. Do not add emulation for a Go build that runs on `$BUILDPLATFORM` and
cross-compiles with `GOOS` and `GOARCH`. Buildx can use an existing binfmt
installation, but setting up a builder does not itself install QEMU.

Treat base-image freshness and layer caching as separate controls: pulling
referenced images does not imply a no-cache build.
