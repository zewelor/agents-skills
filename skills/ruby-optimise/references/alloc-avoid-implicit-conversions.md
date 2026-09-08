---
title: Hoist Only Invariant Conversions
tags: alloc, conversions, invariants
---

## Hoist Only Invariant Conversions

Hoist a conversion only when its input and result stay constant for the entire
loop, and when conversion timing has no observable side effects. Preserve the
log payload, value types, and per-item timestamps. Treat a switch from event
time to batch time as a separate behavior change.

Assume `generated_at` is a fixed Time supplied for this report and product
attributes are pure readers. Keep the logger's hash contract unchanged:

**Before (repeat the same report-time conversion):**

```ruby
def report_entries(products, generated_at:)
  products.map do |product|
    { sku: product.sku.to_s, quantity: product.quantity.to_s,
      timestamp: generated_at.to_s }
  end
end
```

**Alternative (convert the invariant report time once):**

```ruby
def report_entries(products, generated_at:)
  timestamp = nil
  products.map do |product|
    sku = product.sku.to_s
    quantity = product.quantity.to_s
    timestamp ||= generated_at.to_s
    { sku: sku, quantity: quantity, timestamp: timestamp.dup }
  end
end
```

Retain independent timestamp strings if consumers may mutate entries, as above.
Measure whether avoiding repeated formatting outweighs the retained copies.
For an empty input, keep the conversion unevaluated. Do not hoist `Time.now`
when a fresh event time is required for each item.

Do not add type-checking scaffolding around plain `Array#to_a`: it already
returns that array. Inspect custom enumerables before assuming conversion cost.
