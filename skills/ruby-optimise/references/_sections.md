# Select a Performance Investigation

Prioritize measured cost. Use these categories to find relevant examples;
do not infer universal speedups or a fixed optimization order from them.

| Prefix | Evidence to inspect | Main tradeoff |
| --- | --- | --- |
| `alloc-` | Allocation profile and retained objects | Sharing can change ownership and mutability |
| `enum-` | Traversal count and intermediate collections | Fusion changes evaluation order; laziness skips work |
| `io-` | Query count, query plan, I/O time, and peak memory | Batching, caching, and SQL can change consistency and callbacks |
| `str-` | String allocation or substitution hot path | Mutation, encoding, and replacement order |
| `meth-` | Dispatch or callback allocation in a hot path | Reflection, visibility, and dynamic behavior |
| `ds-` | Lookup volume, collection size, and key calculation | Equality, ordering, and conversion cost |
| `conc-` | I/O waits or CPU saturation under representative load | Resource bounds, isolation, failures, and ordering |
| `runtime-` | Boot time, JIT warmup, GC time, and RSS | Version-specific configuration and memory/latency balance |
