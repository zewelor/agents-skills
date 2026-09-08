---
title: Reduce Measured Contention With Local Results
tags: conc, threads, mutex
---

## Reduce Measured Contention With Local Results

Keep a Mutex when a shared invariant requires it. Do not assume that any lock
eliminates the benefit of concurrency; measure contention first. Use independent
partial results when the operation can be partitioned without changing results.

Submit bounded batches through the executor chosen by the project. Give each
worker its own accumulator instead of mutating a global Hash:

```ruby
def count_batch(products)
  products.each_with_object(Hash.new(0)) do |product, totals|
    totals[product.category] += 1
  end
end
```

Wait for all worker results and propagate failures before merging them in the
calling thread. For integer counts, merge partials without shared mutation:

```ruby
def merge_counts(partials)
  partials.each_with_object(Hash.new(0)) do |partial, totals|
    partial.each { |category, count| totals[category] += count }
  end
end
```

Check Hash iteration order if it is observable; concurrent insertion into a
shared Hash may have produced a different order. Do not transfer this integer
sum example to floating-point or non-associative operations without checking
rounding and ordering. Keep product objects read-only during the work.

Follow [bounded work and error propagation](conc-thread-pool-sizing.md). Do not
create one thread per batch for an unbounded dataset. Compare against sequential
counting: removing locks alone does not prove that threads improve throughput.
