---
title: Evaluate Ractors for Isolated CPU Work
tags: conc, ractor, parallel
---

## Evaluate Ractors for Isolated CPU Work

Profile the computation before replacing threads with Ractors. In CRuby,
Ruby-code execution in ordinary threads is constrained by the GVL, while some
native extensions release it. Account for serialization, copying, startup,
and communication overhead; do not promise linear scaling.

1. Verify the exact Ruby version's Ractor messaging API and dependency support.
   Do not copy a Ruby 3.x worker example into Ruby 4.x without checking it.
2. Extract and test the same pure calculation used by the sequential baseline.
   Do not substitute a different algorithm while introducing parallelism.
3. Use a bounded worker count and backpressure, not one Ractor per input.
4. Send supported copies or intentionally shareable data. Do not call
   `Ractor.make_shareable(input.dup)` on nested input and assume the original
   is unaffected: a shallow dup still shares its nested objects.
5. Preserve result ordering and propagate failures. Define how all workers
   finish or are stopped on error before introducing them into a long-lived app.
6. Compare output and caller-owned input before/after, including nested object
   mutability. Measure the complete task including data transfer.

Keep sequential execution if isolation costs exceed the measured benefit.
Read the installed Ruby's official Ractor documentation before selecting its
worker and messaging APIs.
