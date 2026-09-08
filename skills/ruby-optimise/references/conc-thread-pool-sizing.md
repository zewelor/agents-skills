---
title: Bound Concurrent Work and Propagate Failures
tags: conc, threads, limits
---

## Bound Concurrent Work and Propagate Failures

Prefer an existing bounded executor when the project has one. Otherwise, a
bounded batch of threads can be enough for finite I/O work; do not add a queue
and a persistent pool solely for this example. Bound I/O at the client with
connection/read timeouts. Ordinary CRuby threads do not make pure Ruby CPU
work parallel, though native extensions may release the GVL.

For tasks returning one value per input, preserve input order and wait for all
started tasks before propagating a StandardError. Assume task bodies finish or
hit their own timeout; do not use this with unbounded blocking operations.

```ruby
def bounded_map(items, concurrency: 4, &operation)
  unless concurrency.is_a?(Integer) && concurrency.positive?
    raise ArgumentError, "concurrency must be a positive Integer"
  end
  raise ArgumentError, "operation required" unless operation

  items.each_slice(concurrency).flat_map do |batch|
    workers = []
    begin
      batch.each do |item|
        workers << Thread.new do
          begin
            [true, operation.call(item)]
          rescue StandardError => error
            [false, error]
          end
        end
      end
      outcomes = workers.map(&:value)
      failed = outcomes.find { |success, _value| !success }
      raise failed.last if failed
      outcomes.map(&:last)
    ensure
      workers.each(&:join)
    end
  end
end
```

Keep the limit independent of input size. This example bounds active work but
retains its output Array; stream or consume results incrementally if the result
itself is large. Account for database connections per worker. Do not replace a
failed result with nil, silently skip work for a zero limit, or leave workers
running after returning an error.

Test empty input, invalid limits, output ordering (including nil/false), failures,
and peak active work. Compare the complete workload with sequential execution.
