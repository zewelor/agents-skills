---
title: Use Shovel Operator for String Building
tags: str, concatenation, shovel, allocation
---

## Use Shovel Operator for String Building

Append to a buffer owned exclusively by the method when incremental concatenation is measured to be costly. Appending mutates the receiver and can grow its capacity; it does not eliminate formatting allocations. Preserve input coercion: String#<< accepts an Integer as a codepoint, while String#+ does not. Assume String names and delimiter-free fields in this simplified example; use a CSV writer for general CSV.

**Before (new string allocated on each iteration):**

```ruby
def export_products_csv(products)
  result = "id,name,price,stock\n"

  products.each do |product|
    result = result + product.id.to_s       # allocates new string, copies entire buffer
    result = result + ","                    # another allocation + copy of everything so far
    result = result + product.name
    result = result + ","
    result = result + product.price.to_s
    result = result + ","
    result = result + product.stock.to_s
    result = result + "\n"                   # 8 allocations per product
  end

  result
end
```

**Alternative (mutates in place, single buffer grows as needed):**

```ruby
def export_products_csv(products)
  result = String.new("id,name,price,stock\n")

  products.each do |product|
    result << product.id.to_s
    result << ","
    result << product.name
    result << ","
    result << product.price.to_s
    result << ","
    result << product.stock.to_s
    result << "\n"                           # Append to the existing result buffer
  end

  result
end
```
