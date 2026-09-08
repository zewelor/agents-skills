---
title: Reduce Method Chain Depth in Hot Loops
tags: meth, chaining, dispatch, performance
---

## Reduce Method Chain Depth in Hot Loops

Cache intermediate objects within an iteration only when readers are pure and stable for that iteration. Do not hoist values across records. Preserve field evaluation order when it is observable; method dispatch savings alone do not establish a worthwhile optimization.

**Before (repeated chain traversal on every iteration):**

```ruby
def shipping_labels(orders)
  labels = []
  orders.each do |order|
    labels << {
      recipient: order.customer.full_name,            # 2 dispatches per access
      street: order.customer.address.street,           # 3 dispatches per access
      city: order.customer.address.city,               # 3 dispatches per access
      postal_code: order.customer.address.postal_code  # 3 dispatches per access
    }
  end
  labels
end
```

**Alternative (cache intermediate objects before accessing fields):**

```ruby
def shipping_labels(orders)
  orders.map do |order|
    customer = order.customer
    recipient = customer.full_name
    address = customer.address  # Read after full_name, as in the original.

    {
      recipient: recipient,
      street: address.street,
      city: address.city,
      postal_code: address.postal_code
    }
  end
end
```
