# Selected Docker workflow

Use Docker for the agreed development, service, or distribution workflow.
Preserve existing wrappers and commands; distinguish running containers from
building project-owned images.

Apply the build guidance below when building project-owned images. Inspect
each build's context directory, Dockerfile, and effective ignore file; maintain
ignore rules for that context. Use Docker's actual filtering, including negated
patterns. Add inspection to the existing task runner; use a justfile when no
runner exists and a shared command is useful.

The example below covers a local `.` context with the root `.dockerignore` and
no Dockerfile-specific ignore file. For other builds, adapt inspection to their
context and effective ignore rules: Dockerfile-specific ignore files take
precedence over the root file. This root probe does not verify those builds.

```just
show_dockerignore:
    #!/bin/sh
    set -eu
    LC_ALL=C
    export LC_ALL

    test_dir="$(mktemp -d)"
    trap 'rm -rf "$test_dir"' 0 1 2 3 15
    mkdir -p "$test_dir/context"

    docker build --file - --progress=quiet --output "type=local,dest=$test_dir/context" . >/dev/null <<-'EOF'
    # syntax=docker/dockerfile:1
    #check=skip=CopyIgnoredFile
    FROM scratch
    COPY . /context
    EOF

    find "$test_dir/context/context" -type f -print |
      sed "s#^$test_dir/context/context/##" |
      sort > "$test_dir/included"

    cat "$test_dir/included"
    printf '\n%s\n' '---'
    printf 'Total files:\t%s\n' "$(wc -l < "$test_dir/included" | awk '{print $1}')"
    printf 'Total size:\t%s\n' "$(du -sh "$test_dir/context/context" | awk '{print $1}')"
```

Run the selected context-inspection command before accepting image-build or
context changes, including file-layout changes that affect those builds. Review
source, secrets, generated data, hooks, and agent-owned files in the included
list; add ignore rules deliberately.

With project-owned Dockerfiles and GitHub Actions, use `immanuwell/dockerfile-roast` as the
default Dockerfile lint step after checkout. Verify its current inputs and pin
the Action as agreed. Use the default root Dockerfile for a single conventional
file; set `files` for multiple or nonstandard paths. Introduce `droast.toml` and
rule overrides only for a demonstrated project requirement.

Verify the selected development, CI, and runtime targets; inspect the resulting
runtime contract rather than treating a successful lint as a successful image.
