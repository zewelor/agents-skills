---
title: Use Set for Membership Tests
tags: ds, set, lookup, performance
---

## Use Set for Membership Tests

Consider Set for repeated membership checks on a sufficiently large collection. Include set construction and memory in the benchmark. Preserve equality semantics: Array membership uses `==`, while Set relies on `hash` and `eql?`. For example, an Array containing `1` can match `1.0`, while a Set containing `1` does not.

**Before (linear scan on every check):**

```ruby
ALLOWED_STATUSES = ["active", "pending", "trialing"].freeze

def filter_eligible_users(users)
  users.select do |user|
    ALLOWED_STATUSES.include?(user.status)  # O(n) scan per user
  end
end
```

**Alternative (constant-time hash lookup):**

```ruby
require "set"

ALLOWED_STATUSES = Set["active", "pending", "trialing"].freeze

def filter_eligible_users(users)
  users.select do |user|
    ALLOWED_STATUSES.include?(user.status)  # O(1) lookup per user
  end
end
```

**When to prefer Array:**
- Small collections, including the three-status example, unless measurement favors Set
- Ordered iteration is required
- Elements lack a consistent hash/eql? contract or mutate after insertion
