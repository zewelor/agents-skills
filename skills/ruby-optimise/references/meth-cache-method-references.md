---
title: Cache Method References for Repeated Calls
tags: meth, method, cache, lookup
---

## Cache Method References for Repeated Calls

Each call to `obj.method(:name)` allocates a new `Method` object and performs a method lookup. When passing the same method reference to `map`, `select`, or callbacks inside a loop, capture it once before iteration to eliminate repeated lookups and allocations.

**Before (new Method object allocated on every iteration):**

```ruby
class OrderProcessor
  def format(order)
    "#{order.id}: #{order.total}"
  end
end

processor = OrderProcessor.new

batches.each do |batch|
  batch.map(&processor.method(:format))  # New Method + Proc allocated per batch
end
```

**Alternative (single lookup, reused reference):**

```ruby
class OrderProcessor
  def format(order)
    "#{order.id}: #{order.total}"
  end
end

processor = OrderProcessor.new
formatter = processor.method(:format).to_proc  # Capture the reusable adapter once

batches.each do |batch|
  batch.map(&formatter)  # Reuses cached reference
end
```

Cache only for a stable receiver and method implementation. A Method retains its original implementation across later redefinition; block lookup can observe the new one. Do not retain receivers longer than their intended lifetime.
