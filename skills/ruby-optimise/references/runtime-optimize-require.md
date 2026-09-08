---
title: Defer Only Optional Dependency Loading
tags: runtime, require, boot
---

## Defer Only Optional Dependency Loading

Measure boot time and memory before deferring a dependency. Check that it does
not register a framework integration, initializer, or required constant at boot.
Move both the loading cost and possible load failure deliberately; measure the
first-use latency as well as steady-state behavior.

Keep the change limited to one dependency and all of its actual use paths.
For an application that already depends on Prawn and only generates PDFs here:

**Before (Bundler loads Prawn during setup):**

```ruby
# Gemfile
gem "prawn"
```

**Alternative (load explicitly at the sole use site):**

```ruby
# Gemfile
gem "prawn", require: false
```

```ruby
class InvoicePdfService
  def generate(order)
    require "prawn"
    Prawn::Document.new do |pdf|
      pdf.text "Invoice ##{order.invoice_number}"
      pdf.text "Total: #{order.formatted_total}"
    end.render
  end
end
```

Check web, job, console, and test entry points that use this dependency. Preserve
Rails autoloading conventions for application constants. Do not mark unrelated
gems `require: false` without adding and testing their loading paths.
