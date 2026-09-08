---
title: Use each_with_object Over inject for Building Collections
tags: enum, each-with-object, inject, reduce
---

## Use each_with_object Over inject for Building Collections

When building a hash or array with `inject`, each iteration must explicitly return the accumulator. Forgetting to return it can produce an invalid accumulator. Returning a new hash from `merge` is valid, but allocates another hash. `each_with_object` passes the same mutable object throughout, eliminating this class of bugs and producing cleaner code.

**Before (must remember to return accumulator on every iteration):**

```ruby
products_by_sku = catalog.inject({}) do |hash, product|
  hash[product.sku] = product
  hash  # Easy to forget — omitting this returns the Product, breaking the accumulator
end

order_totals = line_items.inject({}) do |totals, item|
  totals[item.order_id] = totals.fetch(item.order_id, 0) + item.price
  totals  # Must return totals on every branch
end
```

**Alternative (mutates single object in place, no return needed):**

```ruby
products_by_sku = catalog.each_with_object({}) do |product, hash|
  hash[product.sku] = product  # Accumulator is always the same object
end

order_totals = line_items.each_with_object({}) do |item, totals|
  totals[item.order_id] = totals.fetch(item.order_id, 0) + item.price
end
```
