---
title: Cache Only an Accepted Data Snapshot
tags: io, cache, consistency
---

## Cache Only an Accepted Data Snapshot

Treat caching as a consistency change, not a transparent refactoring. Establish
acceptable staleness, invalidation, output shape, and who may see the data before
adding a cache. Scope keys to every dimension affecting the result, such as a
tenant, authorization policy, locale, or query parameters. Do not copy a global
catalog key into a scoped application.

Prefer stable scalar data or IDs over cached ActiveRecord instances. For an
explicitly public, global catalog that accepts a five-minute stale name list:

**Before (query on every call):**

```ruby
def category_names
  Category.order(:id).pluck(:name)
end
```

**Alternative (cache the approved public snapshot):**

```ruby
def category_names
  Rails.cache.fetch("public-catalog:category-names:v1", expires_in: 5.minutes) do
    Category.order(:id).pluck(:name)
  end
end
```

Use the cache store's documented concurrency and failure behavior. Test a miss,
hit, expiry/invalidation, scope isolation, and updates; preserve a fresh-read
path when required. Do not invent a universal TTL or imply current database
state was verified by a cache hit.
