---
name: ruby-optimise
description: Diagnose and improve Ruby performance with evidence and behavior-preserving changes. Use for requested performance reviews, profiling, excessive allocations, slow collection processing, N+1 queries, I/O bottlenecks, concurrency tuning, or Ruby runtime optimization. Do not activate solely because ordinary Ruby code uses strings, collections, or ActiveRecord.
---

# Ruby Performance

## Workflow

1. Read the requested scope, project instructions, supported Ruby/framework
   versions, and existing performance evidence. Keep performance audits read-only
   unless the user requests implementation.
2. Identify the actual cost using a profile, query log, allocation measurement,
   or a concrete repeated-work path. Read only the references relevant to it.
3. Record a representative baseline and the metric to improve: latency,
   throughput, allocations, peak memory, or query count. Compare under the same
   Ruby, JIT, dataset, warmup, and concurrency conditions. Do not infer numeric
   gains from a reference example or optimize syntax solely because it looks faster.
4. Preserve values and types, nil/false handling, ordering, evaluation count,
   mutation and aliasing, exceptions, laziness, and external side effects.
   Check database consistency, callbacks, and cursor semantics for SQL changes.
5. Implement the smallest change that addresses the measured or demonstrated
   cost within the authorized scope. Keep a clear implementation when the
   alternative adds complexity without a meaningful benefit.
6. Run focused correctness checks and compare the selected metric. Add regression
   cases for semantic boundaries exposed by the transformation. Report missing
   measurements honestly; do not label an unmeasured change a proven speedup.
7. Stop after relevant checks pass. Repeat or broaden validation only for new
   edits, failures, or unresolved concerns.

Treat examples as conditional alternatives, not universal replacements. Reuse
existing authorization; ask only for unresolved decisions. Change production
JIT, GC, concurrency, or database settings only within an approved operational
scope, with a bounded trial, observed results, and a way to restore the prior setting.

## Reference categories

Use these categories for navigation. Prioritize observed cost rather than a
fixed ordering of allocation, I/O, runtime, or code-style changes.

### 1. Object Allocation

- [`alloc-avoid-unnecessary-dup`](references/alloc-avoid-unnecessary-dup.md) - Avoid Unnecessary Object Duplication
- [`alloc-freeze-constants`](references/alloc-freeze-constants.md) - Freeze Constant Collections
- [`alloc-lazy-initialization`](references/alloc-lazy-initialization.md) - Use Lazy Initialization for Expensive Objects
- [`alloc-avoid-temp-arrays`](references/alloc-avoid-temp-arrays.md) - Avoid Temporary Array Creation
- [`alloc-reuse-buffers`](references/alloc-reuse-buffers.md) - Reuse Buffers in Loops
- [`alloc-avoid-implicit-conversions`](references/alloc-avoid-implicit-conversions.md) - Hoist Only Invariant Conversions

### 2. Collection & Enumeration

- [`enum-single-pass`](references/enum-single-pass.md) - Use Single-Pass Collection Transforms
- [`enum-lazy-large-collections`](references/enum-lazy-large-collections.md) - Use Lazy Enumerators for Large Collections
- [`enum-flat-map`](references/enum-flat-map.md) - Use flat_map Instead of map.flatten
- [`enum-each-with-object`](references/enum-each-with-object.md) - Use each_with_object Over inject for Building Collections
- [`enum-avoid-count-in-loops`](references/enum-avoid-count-in-loops.md) - Avoid Recomputing Collection Size in Conditions
- [`enum-chunk-batch-processing`](references/enum-chunk-batch-processing.md) - Use each_slice for Batch Processing

### 3. I/O & Database

- [`io-eager-load-associations`](references/io-eager-load-associations.md) - Eager Load ActiveRecord Associations
- [`io-select-only-needed-columns`](references/io-select-only-needed-columns.md) - Select Only Needed Columns
- [`io-batch-find-each`](references/io-batch-find-each.md) - Use find_each for Large Record Sets
- [`io-avoid-queries-in-loops`](references/io-avoid-queries-in-loops.md) - Bulk Load Without Losing Lookup Semantics
- [`io-stream-large-files`](references/io-stream-large-files.md) - Stream Records With the Same Parser
- [`io-connection-pool-sizing`](references/io-connection-pool-sizing.md) - Size Each Connection Pool Against Its Process
- [`io-cache-expensive-queries`](references/io-cache-expensive-queries.md) - Cache Only an Accepted Data Snapshot

### 4. String Handling

- [`str-frozen-literals`](references/str-frozen-literals.md) - Enable Frozen String Literals
- [`str-shovel-over-plus`](references/str-shovel-over-plus.md) - Use Shovel Operator for String Building
- [`str-interpolation-over-concatenation`](references/str-interpolation-over-concatenation.md) - Use String Interpolation Over Concatenation
- [`str-avoid-repeated-gsub`](references/str-avoid-repeated-gsub.md) - Chain gsub Calls into a Single Replacement
- [`str-symbol-for-identifiers`](references/str-symbol-for-identifiers.md) - Keep Hash Key Types at API Boundaries

### 5. Method & Dispatch

- [`meth-avoid-method-missing-hot-paths`](references/meth-avoid-method-missing-hot-paths.md) - Avoid method_missing in Hot Paths
- [`meth-cache-method-references`](references/meth-cache-method-references.md) - Cache Method References for Repeated Calls
- [`meth-block-vs-proc`](references/meth-block-vs-proc.md) - Pass Blocks Directly Instead of Converting to Proc
- [`meth-avoid-dynamic-send`](references/meth-avoid-dynamic-send.md) - Avoid Dynamic send in Performance-Critical Code
- [`meth-reduce-method-chain-depth`](references/meth-reduce-method-chain-depth.md) - Reduce Method Chain Depth in Hot Loops

### 6. Data Structures

- [`ds-set-for-membership`](references/ds-set-for-membership.md) - Use Set for Membership Tests
- [`ds-struct-over-openstruct`](references/ds-struct-over-openstruct.md) - Use Struct Over OpenStruct
- [`ds-sort-by-over-sort`](references/ds-sort-by-over-sort.md) - Use sort_by Instead of sort with Block
- [`ds-array-preallocation`](references/ds-array-preallocation.md) - Preallocate Arrays When Size Is Known
- [`ds-hash-default-value`](references/ds-hash-default-value.md) - Use Hash Default Values Instead of Conditional Assignment

### 7. Concurrency

- [`conc-fiber-for-io`](references/conc-fiber-for-io.md) - Use an Existing Scheduler for Bounded I/O
- [`conc-thread-pool-sizing`](references/conc-thread-pool-sizing.md) - Bound Concurrent Work and Propagate Failures
- [`conc-ractor-cpu-bound`](references/conc-ractor-cpu-bound.md) - Evaluate Ractors for Isolated CPU Work
- [`conc-avoid-shared-mutable-state`](references/conc-avoid-shared-mutable-state.md) - Reduce Measured Contention With Local Results

### 8. Runtime & Configuration

- [`runtime-enable-yjit`](references/runtime-enable-yjit.md) - Evaluate YJIT for the Target Workload
- [`runtime-tune-gc-parameters`](references/runtime-tune-gc-parameters.md) - Measure GC Before Tuning Startup Parameters
- [`runtime-frozen-string-literal-default`](references/runtime-frozen-string-literal-default.md) - Adopt Frozen Literals Without Breaking Mutation
- [`runtime-optimize-require`](references/runtime-optimize-require.md) - Defer Only Optional Dependency Loading

## Supporting references

Read [category guidance](references/_sections.md) to select an approach.
Use the [rule template](assets/templates/_template.md) when maintaining this skill.
