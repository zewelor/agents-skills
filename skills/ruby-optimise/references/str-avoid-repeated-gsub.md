---
title: Chain gsub Calls into a Single Replacement
tags: str, gsub, regex, replacement
---

## Chain gsub Calls into a Single Replacement

Combine substitutions only when matches are independent and later passes do not need to process text produced by earlier passes. Preserve encoding, match precedence, and replacement semantics. Measure the hot path instead of assuming a speedup. In the HTML example, escaping `&` first makes the single-pass replacement equivalent for the five listed characters.

**Before (each gsub scans and allocates a new string):**

```ruby
def sanitize_user_input(raw_input)
  result = raw_input
    .gsub("&", "&amp;")        # scan 1, allocation 1
    .gsub("<", "&lt;")          # scan 2, allocation 2
    .gsub(">", "&gt;")          # scan 3, allocation 3
    .gsub('"', "&quot;")        # scan 4, allocation 4
    .gsub("'", "&#39;")         # scan 5, allocation 5 — 5 full passes over the string
  result
end

def normalize_product_slug(name)
  name
    .gsub(/\s+/, "-")           # first pass: whitespace to hyphens
    .gsub(/[^\w-]/, "")         # second pass: strip non-word chars
    .gsub(/--+/, "-")           # third pass: collapse double hyphens
    .downcase
end
```

**Alternative (single scan with hash replacement or combined regex):**

```ruby
HTML_ESCAPE = { "&" => "&amp;", "<" => "&lt;", ">" => "&gt;",
                '"' => "&quot;", "'" => "&#39;" }.freeze
HTML_ESCAPE_PATTERN = Regexp.union(HTML_ESCAPE.keys).freeze

def sanitize_user_input(raw_input)
  raw_input.gsub(HTML_ESCAPE_PATTERN, HTML_ESCAPE)   # one scan, one allocation
end

def normalize_product_slug(name)
  # Keep dependent passes: removing punctuation can create adjacent hyphens.
  name.gsub(/\s+/, "-").gsub(/[^\w-]/, "").gsub(/--+/, "-").downcase
end
```

Preserve the slug contract: `"a.b"` becomes `"ab"`, `"a &- b"` becomes
`"a-b"`, and leading/trailing hyphens remain. Replacing all punctuation with
hyphens or trimming them is a behavior change, not an equivalent optimization.
