---
title: Use sort_by Instead of sort with Block
tags: ds, sorting, sort-by, performance
---

## Use sort_by Instead of sort with Block

Cache sort keys only when key extraction is pure and stable for the sort. Compare the saved key calculations against the extra storage. Preserve the comparison and any required tie-breaking; neither a fixed speedup nor stable ordering of equal keys is guaranteed by this transformation.

**Before (key recomputed on every comparison):**

```ruby
products = catalog.sort { |a, b|
  a.name.downcase <=> b.name.downcase  # downcase called O(n log n) times
}

orders = user.orders.sort { |a, b|
  a.created_at <=> b.created_at  # Method dispatch on every comparison
}
```

**Alternative (key computed once per element):**

```ruby
products = catalog.sort_by { |product|
  product.name.downcase  # downcase called exactly N times, then cached
}

orders = user.orders.sort_by(&:created_at)  # Single pass for key extraction
```

**For descending order:**

```ruby
# Numeric keys — negate
products.sort_by { |p| -p.price }

# Non-numeric keys — use only when reversing ties is acceptable
products.sort_by { |p| p.name.downcase }.reverse
```

Specify a tie-breaker when equal-key order matters. Reversing an ascending result also reverses ties; it is not a general substitute for a descending comparator.
