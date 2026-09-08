---
title: Evaluate YJIT for the Target Workload
tags: runtime, yjit, measurement
---

## Evaluate YJIT for the Target Workload

Check the installed CRuby build and the application framework's existing JIT
configuration first. Do not assume YJIT is absent or disabled. Compare warmup,
steady-state latency, throughput, and process RSS with representative traffic;
YJIT consumes memory for compiled code and metadata and may not help short jobs.

Enable it in the approved startup configuration only after a bounded trial.
For a Puma application already using a Procfile, compare these launch commands:

**Before (existing startup command):**

```text
web: bundle exec puma -C config/puma.rb
```

**Alternative (explicit YJIT startup flag):**

```text
web: bundle exec ruby --yjit -S puma -C config/puma.rb
```

Check the actual application process rather than a separate diagnostic process:

```ruby
yjit_enabled = defined?(RubyVM::YJIT) && RubyVM::YJIT.enabled?
```

Record the previous launch configuration and restore it if the trial exceeds
memory or latency limits. Check version-specific stats keys before using them;
do not log an assumed counter or promise a fixed percentage improvement.

Reference: [CRuby 4.0 YJIT documentation](https://docs.ruby-lang.org/en/4.0/jit/yjit_md.html).
