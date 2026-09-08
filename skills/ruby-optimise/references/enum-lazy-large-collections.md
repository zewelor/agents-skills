---
title: Use Lazy Enumerators for Large Collections
tags: enum, lazy, enumerator, memory
---

## Use Lazy Enumerators for Large Collections

Eager enumeration materializes every intermediate array in full before moving to the next stage. When you only need a subset of results from a large collection, `.lazy` builds a pipeline that processes one element at a time and stops as soon as the final condition is satisfied.

**Before (processes all elements eagerly):**

```ruby
recent_premium = transactions
  .map { |txn| enrich_with_metadata(txn) }       # builds full array of enriched records
  .select { |txn| txn.amount > 500 }              # builds second full array
  .first(10)                                       # discards all but 10 after processing everything

log_entries = File.readlines("/var/log/app.log")   # loads entire file into memory
  .map { |line| JSON.parse(line) }                 # parses every single line
  .select { |entry| entry["level"] == "error" }
  .first(25)
```

**Alternative (lazy pipeline, processes on demand):**

```ruby
recent_premium = transactions
  .lazy
  .map { |txn| enrich_with_metadata(txn) }
  .select { |txn| txn.amount > 500 }
  .first(10)                                       # stops after finding 10 matches

log_entries = File.foreach("/var/log/app.log")     # streams line by line
  .lazy
  .map { |line| JSON.parse(line) }
  .select { |entry| entry["level"] == "error" }
  .first(25)
```

Use only when skipped enrichment/parsing has no required side effects and stopping early is intended; later parse errors may no longer be raised. A lazy pipeline does not make an already-loaded Array or an ActiveRecord relation a streaming source. Use the appropriate source API and verify early-exit resource cleanup.
