---
title: Avoid Dynamic send in Performance-Critical Code
tags: meth, send, dynamic, dispatch
---

## Avoid Dynamic send in Performance-Critical Code

Replace dynamic dispatch only for a fixed, approved format set on a measured hot path. Preserve accepted string/symbol inputs and validate unsupported formats before iteration, including empty inputs. Do not infer inline-cache or JIT behavior solely from the presence of `send`.

**Before (dynamic dispatch over a fixed format set):**

```ruby
class OrderExporter
  def to_csv(order)
    order.values.join(",")
  end

  def to_json(order)
    order.to_h.to_json
  end

  def export_all(orders, format)
    format = format.to_s
    raise ArgumentError, "unsupported format: #{format}" unless %w[csv json].include?(format)
    method_name = "to_#{format}"
    orders.map do |order|
      send(method_name, order)  # Runtime lookup on every iteration
    end
  end
end
```

**Alternative (explicit dispatch over the same formats):**

```ruby
class OrderExporter
  def to_csv(order)
    order.values.join(",")
  end

  def to_json(order)
    order.to_h.to_json
  end

  def export_all(orders, format)
    format = format.to_s
    case format
    when "csv"
      orders.map { |order| to_csv(order) }   # Direct dispatch, cacheable
    when "json"
      orders.map { |order| to_json(order) }  # Direct dispatch, cacheable
    else
      raise ArgumentError, "unsupported format: #{format}"
    end
  end
end
```

**When `send` is acceptable:**
- Metaprogramming frameworks (ORMs, serializers) where dynamism is the point
- One-off calls outside hot paths
- Test helpers accessing private methods

Require `json` for `to_json`. Keep dynamic dispatch when plugins or subclasses extend the accepted format set. Treat the CSV-like join as restricted to fields without delimiters, quotes, or newlines; it is not a general CSV encoder.
