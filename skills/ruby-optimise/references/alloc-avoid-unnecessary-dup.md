---
title: Avoid Unnecessary Object Duplication
tags: alloc, dup, clone, memory
---

## Avoid Unnecessary Object Duplication

Calling `.dup` or `.clone` inside loops creates a new heap object per iteration, multiplying GC pressure linearly with the collection size. Share a frozen object only when callers require neither independent mutable copies nor distinct identity. Preserve `dup` otherwise; freezing is a contract change when mutation was supported.

**Before (allocates a new object per iteration):**

```ruby
class OrderExporter
  HEADER_TEMPLATE = ["Order ID", "Customer", "Total", "Status"]

  def export(orders)
    rows = []
    orders.each do |order|
      header = HEADER_TEMPLATE.dup  # Allocates a new array every iteration
      rows << header
      rows << [order.id, order.customer_name, order.total, order.status]
    end
    rows
  end
end
```

**Alternative (share only the read-only header):**

```ruby
class OrderExporter
  HEADER_TEMPLATE = ["Order ID", "Customer", "Total", "Status"].map(&:freeze).freeze

  def export(orders)
    rows = []
    orders.each do |order|
      rows << HEADER_TEMPLATE
      rows << [order.id, order.customer_name, order.total, order.status]
    end
    rows
  end
end
```

**When `.dup` IS appropriate:**
- When the caller will mutate the returned object
- When building independent modified copies from a template, including inside a loop
- When passing data across thread boundaries that requires isolation
