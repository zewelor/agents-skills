---
title: Use Struct Over OpenStruct
tags: ds, struct, openstruct, allocation
---

## Use Struct Over OpenStruct

Consider Struct only for an established fixed schema. Check construction, missing fields, extra fields, mutation, equality, reflection, and serialization before replacing OpenStruct. Measure the workload rather than assuming a multiplier. Treat conversion to Data as an explicit mutability/API change.

**Before (dynamic method definition on each instantiation):**

```ruby
def parse_api_response(raw_data)
  raw_data.map do |entry|
    OpenStruct.new(                      # Dynamically defines methods per key
      name: entry["name"],
      email: entry["email"],
      role: entry["role"],
      created_at: Time.parse(entry["created_at"])
    )
  end
end
```

**Alternative (fixed layout, precompiled accessors):**

```ruby
UserRecord = Struct.new(:name, :email, :role, :created_at, keyword_init: true)

def parse_api_response(raw_data)
  raw_data.map do |entry|
    UserRecord.new(
      name: entry["name"],
      email: entry["email"],
      role: entry["role"],
      created_at: Time.parse(entry["created_at"])
    )
  end
end
```

**Alternative (Data class in Ruby 3.2+):**

```ruby
UserRecord = Data.define(:name, :email, :role, :created_at)

# Data prevents member reassignment, but nested mutable objects remain mutable.
record = UserRecord.new(name: "Jane", email: "jane@example.com", role: "admin", created_at: Time.now)
```

Require `ostruct` and `time` for the first example, and `time` for Time.parse in the alternatives. Use Data only on Ruby 3.2+ and verify whether member values must also be copied/frozen.
