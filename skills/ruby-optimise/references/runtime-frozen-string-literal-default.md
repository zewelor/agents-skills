---
title: Adopt Frozen Literals Without Breaking Mutation
tags: runtime, frozen, strings
---

## Adopt Frozen Literals Without Breaking Mutation

Prefer the existing project convention. Add the per-file magic comment only
after checking whether returned literals or local buffers must remain mutable.
Do not describe ordinary constant lookup as allocating a new object: a constant
already refers to its assigned value. Interpolated strings and operations such
as concatenation can still allocate.

Place the magic comment at the start of the Ruby file. Preserve a mutable return
value with unary `+` when that is the method's contract:

```ruby
# frozen_string_literal: true

def initial_status
  +"pending"
end
```

If the project already uses RuboCop, express the selected convention in its
existing configuration; do not install another linter solely for this rule:

```yaml
Style/FrozenStringLiteralComment:
  Enabled: true
  EnforcedStyle: always
```

Check mutation through aliases, callers, `<<`, `replace`, and `force_encoding`.
Run the affected tests with the pragma enabled. Avoid a process-wide Ruby flag
as a shortcut: it can affect dependency files as well as application files.
Treat that rollout as a separately scoped compatibility change.

See [per-file frozen literals](str-frozen-literals.md).
