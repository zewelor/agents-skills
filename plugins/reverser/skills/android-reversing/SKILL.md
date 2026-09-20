---
name: android-reversing
description: Analyze Android APK, DEX, manifest, resources, Java or Kotlin reconstruction, and JNI boundaries with project-pinned Droid ASC and isolated JADX. Use for Android package triage, exported-component review, class inventory, reference or single-class searches, full decompilation, multidex or split-package limitations, and mapping native methods to `.so` libraries. Do not use for a standalone native binary after the relevant library and ABI are already known; use ghidra-reversing instead.
---

# Android Reversing

Read and apply the shared [evidence method](../../references/evidence-method.md)
before starting analysis. Use the Android-specific decisions below to select
and operate the parser.

Locate the runtime checkout from the current workspace or a path supplied by the user. Accept it only when `README.md`, `AGENTS.md`, `mise.toml`, `compose.yaml`, and `docker/jadx/Dockerfile` identify the expected reverser toolchain. Do not scan unrelated home directories or assume a machine-specific path. If the checkout cannot be located, report that prerequisite instead of improvising another toolchain. Treat the checkout's current files as authoritative.

## Establish the question and sample

- Inspect the archive for `AndroidManifest.xml`, every `classes*.dex`, resources, assets, and `lib/<abi>/*.so`.
- Detect a base-only or incomplete split APK set and state that limitation. Never combine results from samples whose hashes differ.
- Do not install the APK or plugins taken from it.

## Select the parser

- Use project-pinned Droid ASC through `mise exec -- droidasc` for a trusted sample when the question needs only the manifest, a filtered class inventory through `listclass`, references to a string/type/method/field, or one known class.
- Use `droidasc listclass <apk> --prefix <package>` to locate classes across all DEX entries without generating a full source tree. Preserve the command and output with the other ASC evidence.
- Put `findrefs` options such as `--threads` and `--debug` before the APK path. Treat string patterns as regular expressions and escape metacharacters for literal matches.
- Use the Compose `jadx` service for untrusted input, resources, nested classes, broader reconstruction, or a complete code map. Keep `network_mode: none`, the read-only input mount, and `--user "$(id -u):$(id -g)"` intact.
- Do not infer absence from a negative ASC search. Account for unsupported DEX constructs, reflection, indirect calls, dynamic loading, and result truncation.

## Analyze progressively

1. Start with the decoded manifest and resources. Identify package identity, SDK levels, permissions, exported components, intent filters, providers, network security configuration, and relevant entry points.
2. Search generated output with `rg`, then decompile only the classes needed to answer the question. Use full output only when the narrower route is insufficient.
3. Preserve the JADX log and exit status. Inspect reported decode failures, missing classes, and bad-code warnings; generated files alone do not prove a complete run.
4. For disputed control flow, compare normal output with narrowly scoped `simple` or `fallback` views and verify material claims against DEX instructions.
5. For JNI, map `System.loadLibrary`, `native` declarations, dynamic or static registration, method signatures, library filenames, and ABI. Hand the exact `.so` and unresolved native question to `ghidra-reversing`.

## Preserve evidence

- Store generated ASC and JADX output under `analysis/<case>/asc/` and `analysis/<case>/jadx/`. Keep durable conclusions in `analysis/<case>/notes.md`.
- Treat reconstructed Java as decompiler output, not original source. Confirm security-relevant or disputed conclusions with independent DEX or native evidence.
