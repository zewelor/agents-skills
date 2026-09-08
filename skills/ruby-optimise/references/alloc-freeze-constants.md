---
title: Freeze Constant Collections
tags: alloc, freeze, constants, immutable
---

## Freeze Constant Collections

Freeze constants to prevent accidental mutation, not to avoid reallocation on lookup: reading a constant already returns the assigned object. Freeze nested mutable members separately when required. Treat the filter example as a bug fix for shared state; it deliberately stops mutating `DEFAULT_FILTERS`.

**Before (mutable constants, risk of shared-state corruption):**

```ruby
class ProductCatalog
  ALLOWED_CATEGORIES = ["electronics", "clothing", "home", "garden"]
  DEFAULT_FILTERS = { in_stock: true, min_rating: 3.0 }
  SORT_OPTIONS = [:price_asc, :price_desc, :newest, :rating]

  def filter_products(products, category:)
    unless ALLOWED_CATEGORIES.include?(category)
      raise ArgumentError, "invalid category"
    end

    filters = DEFAULT_FILTERS  # Shares the mutable reference
    filters[:category] = category  # Mutates the constant for all callers
    apply_filters(products, filters)
  end
end
```

**Alternative (frozen constants, immutable and safe):**

```ruby
class ProductCatalog
  ALLOWED_CATEGORIES = ["electronics", "clothing", "home", "garden"].map(&:freeze).freeze
  DEFAULT_FILTERS = { in_stock: true, min_rating: 3.0 }.freeze
  SORT_OPTIONS = [:price_asc, :price_desc, :newest, :rating].freeze

  def filter_products(products, category:)
    unless ALLOWED_CATEGORIES.include?(category)
      raise ArgumentError, "invalid category"
    end

    filters = DEFAULT_FILTERS.merge(category: category)  # Returns a new hash
    apply_filters(products, filters)
  end
end
```

**Deep freeze nested structures:**

```ruby
SHIPPING_RATES = {
  domestic: { standard: 5.99, express: 12.99 }.freeze,
  international: { standard: 19.99, express: 39.99 }.freeze
}.freeze
```
