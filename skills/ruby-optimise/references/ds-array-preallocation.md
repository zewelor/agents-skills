---
title: Preallocate Arrays When Size Is Known
tags: ds, array, preallocation, memory
---

## Preallocate Arrays When Size Is Known

Use `Array.new(n)` with a block for a known result size when it improves the measured path. Assume an Integer `month_count` in this example; preserve the original empty result for non-positive counts. Avoid assumptions about internal capacity growth. Profile repeated `select` scans first: their cost can dominate array growth.

**Before (repeated resizing as array grows):**

```ruby
def compute_monthly_totals(transactions, month_count)
  totals = []
  month_count.times do |i|
    month_transactions = transactions.select { |t| t.month_index == i }
    totals << month_transactions.sum(&:amount)  # Resizes at capacity boundaries
  end
  totals
end
```

**Alternative (single allocation with exact size):**

```ruby
def compute_monthly_totals(transactions, month_count)
  return [] if month_count <= 0  # Preserve Integer#times behavior for negatives.

  Array.new(month_count) do |i|
    month_transactions = transactions.select { |t| t.month_index == i }
    month_transactions.sum(&:amount)  # No resizing needed
  end
end
```

**Also applies to map/collect:**

```ruby
# Prefer a direct map for a one-to-one transformation
totals = transactions.map(&:amount)
```

**When preallocation matters most:**
- Large arrays with measurable growth overhead
- Latency-sensitive code paths
- Memory-constrained environments
