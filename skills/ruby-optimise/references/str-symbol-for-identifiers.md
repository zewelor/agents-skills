---
title: Keep Hash Key Types at API Boundaries
tags: str, symbols, hashes
---

## Keep Hash Key Types at API Boundaries

Choose symbol keys for an internal schema when it matches project conventions.
Keep string-keyed JSON and other public inputs/outputs unchanged unless an API
migration is explicitly requested. Do not replace `params["user_id"]` with
`params[:user_id]`: a plain Hash treats these as different keys.

Normalize only known fields at an intentional boundary. Preserve external key
and value types when returning data:

```ruby
def order_attributes(params)
  { user_id: params["user_id"], product_id: params["product_id"],
    quantity: params["quantity"] }
end

def order_payload(attributes)
  { "user_id" => attributes[:user_id], "product_id" => attributes[:product_id],
    "quantity" => attributes[:quantity] }
end
```

Keep unknown-field handling and missing-key behavior consistent with the public
contract. Avoid converting arbitrary external keys to symbols for a supposed
universal speedup. Benchmark real lookups before changing a stable schema for
performance, including any normalization cost.
