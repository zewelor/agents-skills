---
title: Avoid Recomputing Collection Size in Conditions
tags: enum, count, size, performance
---

## Avoid Recomputing Collection Size in Conditions

Use an emptiness check appropriate to the actual receiver. Array#length and blockless Array#count do not traverse the array. Enumerable#any? tests truthiness unless a block is given: `[nil, false].any?` is false despite the array being nonempty. Inspect unloaded ActiveRecord relations and their generated SQL separately.

**Before (full traversal to check presence):**

```ruby
if order.line_items.count > 0            # executes SELECT COUNT(*) on every call
  apply_discount(order)
end

pending = users.select(&:pending?)
if pending.count == 0                     # already an array, but reads less clearly
  notify_admin("No pending users")
end

while unprocessed_jobs.count > 0          # Array count is constant-time; this is a clarity change
  process(unprocessed_jobs.shift)
end
```

**Alternative (short-circuit presence checks):**

```ruby
if order.line_items.any?                  # Check SQL for the installed Rails version and loading state
  apply_discount(order)
end

pending = users.select(&:pending?)
if pending.empty?
  notify_admin("No pending users")
end

until unprocessed_jobs.empty?             # O(1) check per iteration
  process(unprocessed_jobs.shift)
end
```
