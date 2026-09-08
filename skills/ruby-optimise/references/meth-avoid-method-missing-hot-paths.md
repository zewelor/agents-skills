---
title: Avoid method_missing in Hot Paths
tags: meth, method-missing, dispatch, performance
---

## Avoid method_missing in Hot Paths

Consider explicit readers for a fixed schema when profiling shows dynamic dispatch matters. Require all four symbol keys in the example and treat zero-argument reads as the supported API. Keep dynamic access when keys can appear later; generated readers change reflection and invalid-call behavior. Do not claim a universal dispatch/JIT multiplier.

**Before (full method resolution on every access):**

```ruby
class UserProfile
  def initialize(attrs)
    required = %i[email name role department]
    raise ArgumentError, "expected fixed profile schema" unless attrs.keys.sort == required.sort
    @attrs = attrs
  end

  def method_missing(name, *args)
    if args.empty? && @attrs.key?(name)
      @attrs[name]  # Triggers full method lookup chain every time
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    @attrs.key?(name) || super  # Must also be overridden for consistency
  end
end

# In a request loop — method_missing fires on each iteration
users.each do |user|
  profile = UserProfile.new(user)
  profile.email  # Dynamic reader for the fixed schema
end
```

**Alternative (generates real methods the VM can cache):**

```ruby
class UserProfile
  ATTRIBUTES = %i[email name role department].freeze

  def initialize(attrs)
    required = %i[email name role department]
    raise ArgumentError, "expected fixed profile schema" unless attrs.keys.sort == required.sort
    @attrs = attrs
  end

  ATTRIBUTES.each do |attr|
    define_method(attr) do
      @attrs[attr]
    end
  end
end

# In a request loop — direct dispatch, fully cacheable
users.each do |user|
  profile = UserProfile.new(user)
  profile.email  # Real method, normal dispatch speed
end
```
