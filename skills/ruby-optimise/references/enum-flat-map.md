---
title: Use flat_map Instead of map.flatten
tags: enum, flat-map, flatten, arrays
---

## Use flat_map Instead of map.flatten

Replace `map { ... }.flatten(1)` with `flat_map` when the block returns ordinary arrays and interleaving mapping with flattening is safe. Preserve flattening depth: plain `flatten` is recursive, while `flat_map` flattens one level. Check custom `to_ary` behavior and side effects; measure allocations instead of promising a fixed reduction.

**Before (intermediate nested array):**

```ruby
all_line_items = orders
  .map { |order| order.line_items }   # builds array of arrays
  .flatten(1)                          # flatten exactly one level

tag_names = products
  .map { |product| product.categories.map(&:name) }  # nested array of arrays of strings
  .flatten(1)
```

**Alternative (single flattened pass):**

```ruby
all_line_items = orders
  .flat_map { |order| order.line_items }  # yields directly into one array

tag_names = products
  .flat_map { |product| product.categories.map(&:name) }
```

Keep recursive flattening when required: for `[[[1]]]`, `map { |x| x }.flatten`
returns `[1]`, while `flat_map { |x| x }` returns `[[1]]`.
