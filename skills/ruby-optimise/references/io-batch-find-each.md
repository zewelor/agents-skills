---
title: Use find_each for Large Record Sets
tags: io, batch, find-each, activerecord, memory
---

## Use find_each for Large Record Sets

Use ActiveRecord batch iteration to bound record loading when the operation does not require the original relation ordering or a single read snapshot. Check the installed Rails version: scoped order may be ignored or rejected, and cursor APIs vary. Keep the cursor unique and stable; verify concurrent changes, retries, callbacks, and side effects.

**Before (loads entire table into memory at once):**

```ruby
class AccountCleanupJob
  def perform
    User.where("last_login_at < ?", 2.years.ago).each do |user|  # loads all matching rows into memory
      user.anonymize_personal_data!
      user.update!(status: :archived)
    end
  end
end
```

**Alternative (bound the loaded records per batch):**

```ruby
class AccountCleanupJob
  def perform
    User.where("last_login_at < ?", 2.years.ago).find_each(batch_size: 500, error_on_ignore: true) do |user|
      user.anonymize_personal_data!
      user.update!(status: :archived)
    end
  end
end
```

Measure peak memory including associations and retained results, not only the batch size. Do not run the cleanup example against production merely to benchmark it. Reference: [Rails 8.1 batches](https://api.rubyonrails.org/v8.1.3/classes/ActiveRecord/Batches.html).
