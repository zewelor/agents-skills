---
title: Bulk Load Without Losing Lookup Semantics
tags: io, bulk, queries
---

## Bulk Load Without Losing Lookup Semantics

Bulk-load records only after checking ID types, missing IDs, duplicate input,
ordering, snapshot consistency, and side-effect timing. `where` omits missing
records; `find` raises. Do not replace a missing lookup with nil dereferencing
or silently skip it.

For a bounded read-only batch of existing integer IDs, preserve requested order
and duplicates while computing labels from pure model readers:

**Before (one lookup for each input ID):**

```ruby
def order_labels(order_ids)
  order_ids.map { |id| Order.find(id).label }
end
```

**Alternative (one query for the same bounded batch):**

```ruby
def order_labels(order_ids)
  orders = Order.where(id: order_ids).index_by(&:id)
  order_ids.map do |id|
    order = orders.fetch(id) do
      raise ActiveRecord::RecordNotFound, "Order not found: #{id}"
    end
    order.label
  end
end
```

Check exception metadata/message requirements: the explicit error above
preserves the class, not ActiveRecord's exact generated exception. Normalize
external IDs at the existing validation boundary rather than assuming string
IDs match integer hash keys. For a large input, use bounded batches respecting
the database parameter limit and required snapshot semantics.

Do not apply this example blindly around shipping, billing, callbacks, or other
writes: eager loading can change which effects happen before a later failure.
