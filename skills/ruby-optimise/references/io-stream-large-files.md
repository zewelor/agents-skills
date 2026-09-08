---
title: Stream Records With the Same Parser
tags: io, files, streaming
---

## Stream Records With the Same Parser

Stream input with the same record parser and return contract as the original.
Do not replace `split("\n")` with chomped lines and assume identical handling
of blank lines, trailing separators, or CRLF. Use a CSV parser for quoted fields
and embedded newlines; keep CSV options and encoding unchanged.

For a CSV with `sku`, `name`, and `price` headers, compare the same import logic.
Assume each parsed row is valid before writes: streaming moves parsing errors
later, potentially after earlier writes. Preserve atomicity explicitly when
malformed input must cause no partial import.

**Before (materialize every parsed row):**

```ruby
require "csv"
require "bigdecimal"

def import_products(path)
  CSV.read(path, headers: true).each do |row|
    Product.create!(sku: row["sku"], name: row["name"], price: BigDecimal(row["price"]))
  end
  nil
end
```

**Alternative (stream parsed records):**

```ruby
require "csv"
require "bigdecimal"

def import_products(path)
  CSV.foreach(path, headers: true) do |row|
    Product.create!(sku: row["sku"], name: row["name"], price: BigDecimal(row["price"]))
  end
  nil
end
```

Use the project's installed CSV dependency. Test quoted fields, CRLF, embedded
newlines, empty files, malformed rows, and cleanup on exceptions. Measure peak
memory including retained results and record size; streaming is not a bound on
the size of an individual record.
