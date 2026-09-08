---
title: Eager Load ActiveRecord Associations
tags: io, eager-loading, n-plus-one, activerecord
---

## Eager Load ActiveRecord Associations

Inspect query logs for associations loaded or counted per row. In this example both comments and line_items can add a query for each order. Choose preloading based on the actual association type, scopes, and required fields; `includes` may use separate queries or a join, so verify rather than promising a fixed query count.

**Before (fires a query per iteration):**

```ruby
class OrderSummaryService
  def generate(user)
    orders = user.orders.where(status: :completed)

    orders.map do |order|
      {
        id: order.id,
        total: order.total,
        comments: order.comments.map(&:body),  # SELECT * FROM comments WHERE order_id = ? (per order)
        items_count: order.line_items.size       # SELECT COUNT(*) FROM line_items WHERE order_id = ? (per order)
      }
    end
  end
end
```

**Alternative (preload the associations used by the loop):**

```ruby
class OrderSummaryService
  def generate(user)
    orders = user.orders
      .where(status: :completed)
      .includes(:comments, :line_items)

    orders.map do |order|
      {
        id: order.id,
        total: order.total,
        comments: order.comments.map(&:body),
        items_count: order.line_items.size
      }
    end
  end
end
```

Measure memory as well as SQL count. Loading every line_item merely to count them may cost more than a counter cache or grouped count; select that alternative only after checking consistency requirements.
