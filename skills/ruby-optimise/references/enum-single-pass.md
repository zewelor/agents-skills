---
title: Use Single-Pass Collection Transforms
tags: enum, single-pass, chaining, arrays
---

## Use Single-Pass Collection Transforms

Fuse `select.map` only when predicates and transformations are pure and interleaving their evaluation preserves the contract. Use `each_with_object` to preserve all mapped values, including nil and false. Use `filter_map` (Ruby 2.7+) only when dropping falsey mapped values is intended. Keep separate passes if side effects or exception order matter.

**Before (multiple intermediate arrays):**

```ruby
active_emails = users
  .select { |user| user.confirmed? && user.active? }  # allocates intermediate array of active users
  .map(&:email)  # allocates second array of emails

discounted_totals = orders
  .select { |order| order.coupon_applied? }
  .map { |order| order.total * 0.85 }  # two passes, two throwaway arrays
```

**Alternative (single-pass transform):**

```ruby
active_emails = users.each_with_object([]) do |user, emails|
  emails << user.email if user.confirmed? && user.active?
end

discounted_totals = orders.each_with_object([]) { |order, totals|
  totals << order.total * 0.85 if order.coupon_applied?
}
```
