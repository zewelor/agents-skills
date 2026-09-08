---
title: Reuse Buffers in Loops
tags: alloc, buffers, loops, reuse
---

## Reuse Buffers in Loops

Reuse a buffer only when each consumer finishes with its contents before the next mutation and does not retain the object. `output << line` copies the string contents here; storing `line` in an Array would retain the shared object. Measure retained capacity and total allocations: formatting and buffer growth can still allocate. Treat this delimited-text example as limited to fields without commas, quotes, or newlines; use a CSV writer for general CSV.

**Before (allocates a new string per iteration):**

```ruby
class CsvExporter
  def generate(orders)
    output = +""
    orders.each do |order|
      line = +""  # New string allocated every iteration
      line << order.id.to_s
      line << ","
      line << order.customer_name
      line << ","
      line << format("%.2f", order.total)
      line << "\n"
      output << line
    end
    output
  end
end
```

**Alternative (reuses a single buffer):**

```ruby
class CsvExporter
  def generate(orders)
    output = +""
    line = +""  # Single allocation, reused across iterations
    orders.each do |order|
      line.clear  # Reset contents; do not assume a particular capacity policy
      line << order.id.to_s
      line << ","
      line << order.customer_name
      line << ","
      line << format("%.2f", order.total)
      line << "\n"
      output << line
    end
    output
  end
end
```

**Same pattern with arrays:**

```ruby
# Incorrect -- allocates per batch
batches.each do |batch|
  ids = []  # New array per batch
  batch.each { |record| ids << record.id }
  process_ids(ids)
end

# Correct -- reuses buffer
ids = []
batches.each do |batch|
  ids.clear  # Reset contents before synchronous consumption
  batch.each { |record| ids << record.id }
  process_ids(ids)
end
```

Keep per-batch arrays if `process_ids` retains them, queues asynchronous work,
or needs an independently mutable input. Reuse is invalid in those cases.
