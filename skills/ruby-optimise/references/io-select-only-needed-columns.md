---
title: Select Only Needed Columns
tags: io, select, pluck, activerecord, memory
---

## Select Only Needed Columns

Loading full ActiveRecord objects when you only need one or two columns wastes memory on attribute storage, type casting, and object overhead. Use `.select` for partial models or `.pluck` when you only need raw values without ActiveRecord instances.

**Before (loads every column into full ActiveRecord objects):**

```ruby
class NewsletterService
  def subscriber_emails
    users = User.where(subscribed: true)  # SELECT * FROM users — loads all columns
    users.map(&:email)                    # instantiates a full User object per row
  end

  def active_user_ids
    User.where(active: true).map(&:id)  # loads all columns just to extract ids
  end
end
```

**Alternative (loads only the columns needed):**

```ruby
class NewsletterService
  def subscriber_emails
    User.where(subscribed: true).pluck(:email)  # SELECT email FROM users — returns plain strings
  end

  def active_user_ids
    User.where(active: true).ids  # SELECT id FROM users — optimized id-only query
  end
end
```

Check that model readers are ordinary attributes: `pluck` bypasses custom Ruby readers and object initialization callbacks. Preserve ordering and nil values. Partial models can raise on access to unloaded fields. Verify SQL and type casting against the installed Rails version.
