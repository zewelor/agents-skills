# Minimal Non-Root Runtimes

- [Non-root users](#non-root-user-creation-when-distroless-is-not-viable)
- [Ruby and Bundler](#ruby--bundler)
- [Debian versions](#debian-version-alignment)

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

For projects already using `ghcr.io/zewelor/ruby`, consider its `-distroless`
variant and match the build image's Debian release. Preserve a project's
compatible maintained image provider unless a change is justified.

Default the image to its nonroot user (UID 65532 for Google Distroless `nonroot`)
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

## Ruby + Bundler

For projects using `ghcr.io/zewelor/ruby`, use its `-slim` build variant and
compatible `-distroless` runtime variant. Otherwise use the project's compatible
maintained Ruby images. Pin the tag to the Ruby version targeted.

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
