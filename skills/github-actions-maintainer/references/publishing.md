## Docker, GHCR, and Buildx Cache

Use the Docker skill for Dockerfile stages, build context, image contents,
runtime users, and BuildKit cache mounts. Keep workflow orchestration here.

- Authenticate to a private registry before any build step whose `FROM` may
  pull a private image.
- Build and smoke-test the native runner platform before publishing a
  multi-platform manifest when this gives useful fast feedback.
- For multi-platform builds, inspect which stages execute target-architecture
  binaries. Choose cross-compilation, QEMU, or native runners based on toolchain
  support, compatibility, and comparable build times and cache conditions.
  When publishing separate per-platform images, merge the manifest only after
  the required builds succeed; per-platform digests can identify the inputs.
- Treat successful cross-compilation and a multi-platform manifest as separate
  from runtime verification. Add a native ARM smoke test when ARM runtime support
  warrants ongoing coverage; do not add a matrix solely because cross-compilation
  is supported.
- When configuring Buildx cache, select restore/export behavior and backend from
  the actual producers and consumers; preserve deliberate restore-only jobs:
  - Use `type=gha,scope=${image_name}` for branch and PR workflows where builds run on `main` or feature branches and inherit branch cache without extra registry tags or package write permissions.
  - Consider `type=registry,ref=${registry}/${image}:buildcache` when cross-ref reuse beyond GitHub cache visibility is needed. GitHub cache can restore from the current and default branch, and PRs also from their base branch; different tags cannot restore each other's caches. A manual event alone does not require registry cache, and tag runs may reuse default-branch cache. Verify the required sharing before adding registry writes.
  - Specify the full OCI reference (`ghcr.io/owner/repo:buildcache`) for registry cache and grant the job `packages: write` permissions.
  - Whenever configuring `type=registry` or switching cache backends, add an inline comment directly next to the cache configuration in the workflow file explaining why that backend was chosen (e.g. noting that tag-triggered builds require registry cache to share layers across release tags).
- Use `mode=max` when intermediate build stages (downloaded dependencies, compiler caches) should be exported.
- Make a cache toggle control both restore and export. If it intentionally
  controls only one direction, name it `restore_cache` or `export_cache`.
- Treat `pull: true` and layer caching as independent: refresh referenced base
  images without implying `no-cache`.
- Do not store credentials in cacheable layers or build arguments. Use BuildKit
  secret or SSH mounts for build-time credentials.
- Add QEMU/binfmt only when a build executes target-architecture binaries.
  Omit it when a toolchain runs on `$BUILDPLATFORM` and cross-compiles artifacts
  for `TARGETOS`/`TARGETARCH`.
- When changing cache behavior or claiming reuse/performance improvements, use
  comparable hosted runs to prove restore/export and reuse. Configuration alone
  proves wiring. Do not require cache experiments for unrelated workflow edits.
- When GHCR retention is in scope, run cleanup only after successful image
  publication, in a job with `packages: write`. Preserve the repository's retention
  policy. For `dataaxiom/ghcr-cleanup-action`, protect persistent/rolling release
  channels (e.g. `latest`, `stable`, `edge`) in `exclude-tags`:

  ```yaml
  - name: Delete old images
    uses: dataaxiom/ghcr-cleanup-action@d52806a0dc70b430571a37da1fde39733ffd640f # v1.2.2
    with:
      keep-n-tagged: 10
      keep-n-untagged: 10
      exclude-tags: latest
      delete-partial-images: true
  ```

## Releases and Supply Chain

- Keep tests read-only and grant release/package writes only after verification
  succeeds.
- Publish immutable version or commit-derived tags. Add a mutable channel such
  as `latest` only when its update semantics are deliberate.
- Capture and expose the pushed image digest. Pin deployed runtime images by
  digest even when a mutable tag is used as a build-stage input.
- Prefer OIDC over long-lived cloud credentials.
- Generate provenance once through a deliberate mechanism. Add SBOM generation
  when consumers or policy use it; avoid duplicate attestations by default.
- Use protected environments for production publication or deployment when a
  manual approval or environment-scoped secret boundary is valuable.
