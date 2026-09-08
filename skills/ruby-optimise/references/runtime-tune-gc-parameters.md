---
title: Measure GC Before Tuning Startup Parameters
tags: runtime, gc, measurement
---

## Measure GC Before Tuning Startup Parameters

Measure GC time, collections, allocations, retained heap, process RSS, and
request latency under representative load before changing settings. Keep the
existing defaults if GC is not the demonstrated bottleneck.

Capture counters around the same workload, without forcing a collection inside
the measured interval:

```ruby
before = GC.stat
run_representative_workload
previous_collections = before.fetch(:count)
collections = GC.stat(:count) - previous_collections
```

Select parameters from the documentation for the exact Ruby version and GC
implementation. Treat `RUBY_GC_*` startup variables as process-launch settings;
do not assign them inside Rails `production.rb` and assume the running collector
was reconfigured. Remove unsupported variables rather than maintaining an
unverified cross-version parameter list.

Change one setting at a time in an approved bounded trial. Start a new process,
check the effective behavior and memory budget, then compare the same workload.
Record the old launch settings so they can be restored. Do not prescribe fixed
heap sizes, growth factors, or pause-time improvements without measurements.

Reference: [CRuby 4.0 GC statistics](https://docs.ruby-lang.org/en/4.0/GC.html).
