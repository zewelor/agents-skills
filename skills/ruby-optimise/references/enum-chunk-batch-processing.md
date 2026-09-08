---
title: Use each_slice for Batch Processing
tags: enum, batch, each-slice, memory
---

## Use each_slice for Batch Processing

Use a streaming source before grouping into bounded batches. `each_slice` does not release an already materialized source Array or turn an ActiveRecord relation into batched SQL. Use Rails batch APIs for database records after checking cursor order, concurrent changes, and retry semantics.

**Before (loads all records then processes):**

```ruby
users = User.where(subscribed: true).to_a  # loads entire result set into memory

users.each do |user|
  NotificationMailer.weekly_digest(user).deliver_later
end

products = Product.all.to_a                 # millions of rows materialized at once
products.each do |product|
  SearchIndex.update(product)               # memory grows unbounded during processing
end
```

**Alternative (processes in fixed-size batches):**

```ruby
User.where(subscribed: true).find_each(batch_size: 1000) do |user|
  NotificationMailer.weekly_digest(user).deliver_later
end

Product.all.find_in_batches(batch_size: 1000) do |batch|
  batch.each { |product| SearchIndex.update(product) }  # Keep the original operation.
end

# For non-ActiveRecord enumerables, use each_slice
large_csv_rows.each_slice(500) do |batch|
  ImportService.process(batch)
end
```

Replace per-record operations with a bulk API only after comparing callbacks, failure/partial-success behavior, ordering, and return contracts. A bulk method name alone is not evidence of equivalence.
