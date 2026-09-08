---
title: Enable Frozen String Literals
tags: str, frozen, literals, gc
---

## Enable Frozen String Literals

Use frozen string literals under the project convention after checking mutation and return contracts. Non-interpolated literals can be reused; interpolated strings and concatenation still allocate. Preserve mutable outputs explicitly. Treat adding the pragma as a compatibility change, not an automatic optimization for every file.

**Before (new string allocated on every call):**

```ruby
class OrderMailer
  def confirmation_subject(order)
    prefix = "Order Confirmation"            # new String allocated each invocation
    separator = " - "                        # another allocation
    prefix + separator + order.reference     # yet another for the concatenation result
  end

  def format_status(order)
    status = "pending"                       # new "pending" every time, even though it never changes
    order.status == status ? "awaiting" : order.status
  end
end
```

**Alternative (literals frozen and deduplicated at compile time):**

```ruby
# frozen_string_literal: true

class OrderMailer
  def confirmation_subject(order)
    prefix = "Order Confirmation"
    separator = " - "
    prefix + separator + order.reference  # Preserve string coercion and mutable result.
  end

  def format_status(order)
    status = "pending"
    order.status == status ? +"awaiting" : order.status
  end
end
```

See also: [Set Frozen String Literal as Project Default](runtime-frozen-string-literal-default.md) for enforcing this pragma across an entire codebase.

**When you need a mutable string in a frozen file:**

```ruby
# frozen_string_literal: true

def build_csv_row(product)
  row = +""                     # unary + creates a mutable copy
  row << product.name
  row << ","
  row << product.price.to_s
  row
end
```
