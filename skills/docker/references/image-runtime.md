# Minimal Non-Root Runtimes

- [Non-root users](#non-root-user-creation-when-distroless-is-not-viable)
- [Ruby and Bundler](#ruby--bundler)
- [Base image parity and version alignment](#base-image-parity-and-version-alignment)

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

In a multi-stage build, use the paths configured by the project and base image
for application files and installed dependencies. Check that the final stage
can find them and that development bind mounts leave required files accessible.

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

Use the base image's suitable nonroot user when available. Otherwise set a
numeric UID/GID in the final stage. If the application looks up account or
group information by name or numeric ID, verify that lookup in the final image. Entries
created in an independent build stage stay in that stage. If the application
needs a home directory, provide it with the permissions it requires.

## Ruby + Bundler

Use the project's Ruby version and lockfile. Install the gem groups needed by
the target stage. If the runtime needs a specific Bundler version, verify that
its RubyGems installation and executable are available in the final image.
For native gems, keep build tools and headers in the build stage and include
the shared libraries the extensions load at runtime. Verify that the runtime
user can start the application with its locked gems.

## Base Image Parity and Version Alignment

Keep distribution-based `dev`, `test`, and `production` stages on the same OS
family and libc. Exclude `scratch` from this comparison because it has no
distribution. If a migration breaks tooling, investigate fixes on the selected
base. Before introducing a split between distribution-based stages, explain
why it is needed and obtain the user's approval.

For dynamically linked binaries and native extensions, verify target
architecture, libc (glibc versus musl), loader, and library ABI compatibility.
Prefer matching Debian releases for Debian build/runtime stages to reduce ABI
mismatches; verify required libraries rather than assuming the suite alone
is sufficient. Select explicit supported suite/version tags and pin digests.

A build-only compiler stage can use a different distribution from the runtime
when its binary is truly static and has no external ABI dependencies. An Alpine Go builder with `CGO_ENABLED=0` can target scratch
or a compatible static runtime; validate the resulting artifact and image.
