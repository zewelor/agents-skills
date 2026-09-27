# Flutter AOT

Identify the owning layer from the archive, not the app's package name. Pair
`libapp.so` with `libflutter.so` from the same APK hash and ABI. Distinguish a
release snapshot from an ordinary JNI implementation.

## Select and validate the frontend

- Read the runtime's pins and help. Prefer its isolated AOTopsy service when
  available; do not assume an ad-hoc `/tmp` installation is reproducible.
- Record engine Dart banner, snapshot hash, parser version and structural profile
  separately. A structural profile label is not the compiler SDK version.
- Run the frontend diagnostic for the selected sample before a full pass. Check
  parse warnings and unknowns; function counts or annotation percentages do not
  establish correctness of a specific function.
- Use Blutter only when a concrete ambiguity warrants another snapshot parser and
  the matching SDK/ABI is supported. Do not treat two parsers' agreement as live
  server proof. Do not run the sample or add runtime hooks as an implicit fallback.

## Recover values before assigning meaning

Use bounded string/function/xref searches over existing output. Follow the
consumer's disassembly to determine what a field means; a generated `f_0x20`
name is an offset, not a semantic label. For constructor options, resolve the
actual pool object and enum value rather than borrowing a dependency's default.

If the runtime ships `scripts/dart_aot_query.py`, inspect its help and query only
the required class, CID, ref or pool index. Supply `classes.jsonl`,
`instances.jsonl`, `pool-debug.jsonl` and the optional exported debug strings.
Preserve raw refs, CID, field offsets, unresolved values and input hashes.
Primitive values absent from the instance export remain unknown; do not invent
an enum index or missing field value. Confirm a recovered enum's role in the
function that consumes it.

Name address spaces explicitly: virtual address, ELF file offset, pool index,
PP byte displacement and object ref are different identifiers. For a disputed
function, compare its bytes with the matched ELF segment and inspect callers;
read pseudocode as reconstruction, not source.

## Runtime example

Use commands from the current checkout; these helpers are optional capabilities,
not prerequisites for every runtime:

```sh
python3 scripts/doctor.py --route flutter --sample analysis/CASE/native/libapp.so --probe
mkdir -p analysis/CASE/aotopsy
python3 scripts/run_tool.py --case CASE aotopsy \
  /workspace/analysis/CASE/native/libapp.so --out /output/CASE/aotopsy
```

Export pool objects/debug strings only when needed, preserving tool help and
exit status. Keep generated data in the case, avoid printing unrelated constants
or secrets, and stop at the evidence sufficient for the requested question.
