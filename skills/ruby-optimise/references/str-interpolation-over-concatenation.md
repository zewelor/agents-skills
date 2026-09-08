---
title: Use String Interpolation Over Concatenation
tags: str, interpolation, concatenation, allocation
---

## Use String Interpolation Over Concatenation

Prefer interpolation for clarity when the embedded values have the intended string representation. Check coercion: `+` expects string-compatible operands, while interpolation calls `to_s` and can silently accept nil or another type. Do not replace the former when its TypeError is part of input validation. Measure actual allocations; interpolated expressions and conversions can allocate too.

**Before (intermediate string per concatenation):**

```ruby
def order_summary(user, order)
  greeting = "Hello, " + user.name + "! "                   # 2 intermediate strings
  details = "Your order #" + order.reference + " for " +
            order.total.to_s + " was placed on " +
            order.placed_at.strftime("%B %d, %Y") + "."     # 4 intermediate strings
  greeting + details                                         # 1 more to join them
end

def product_url(product)
  "/products/" + product.category.slug + "/" + product.slug  # 2 throwaway strings
end
```

**Alternative (interpolation for string-valued inputs):**

```ruby
def order_summary(user, order)
  greeting = "Hello, #{user.name}! "
  details = "Your order ##{order.reference} for #{order.total}" \
            " was placed on #{order.placed_at.strftime("%B %d, %Y")}."
  "#{greeting}#{details}"
end

def product_url(product)
  "/products/#{product.category.slug}/#{product.slug}"
end
```
