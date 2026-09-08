---
title: Pass Blocks Directly Instead of Converting to Proc
tags: meth, block, proc, allocation
---

## Pass Blocks Directly Instead of Converting to Proc

Compare block literals with creating Method/Proc adapters only on a measured path. Keep the chosen project style for ordinary calls. Assume the called methods remain stable during enumeration; a captured Method and later dynamic lookup can differ after redefinition.

**Before (new Proc allocated per call site):**

```ruby
class ProductCatalog
  def initialize(products)
    @products = products
  end

  def format_name(product)
    product.name.strip.downcase
  end

  def normalized_names
    @products.map(&method(:format_name))  # Allocates a new Proc each time
  end

  def active?(product)
    product.active?
  end

  def export_names
    @products.select(&method(:active?)).map(&method(:format_name))  # Two Proc allocations
  end
end
```

**Alternative (block literals, no intermediate Proc):**

```ruby
class ProductCatalog
  def initialize(products)
    @products = products
  end

  def format_name(product)
    product.name.strip.downcase
  end

  def normalized_names
    @products.map { |product| format_name(product) }
  end

  def active?(product)
    product.active?
  end

  def export_names
    @products.select { |product| active?(product) }.map { |product| format_name(product) }
  end
end
```

**Exception:** Using `&:symbol` for simple method calls on the receiver (e.g., `names.map(&:downcase)`) is idiomatic and optimized by most Ruby implementations. The overhead concern applies specifically to `&method(:name)`.
