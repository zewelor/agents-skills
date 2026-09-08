---
title: Size Each Connection Pool Against Its Process
tags: io, pool, database
---

## Size Each Connection Pool Against Its Process

Measure checkout waits before enlarging a pool. Size each process/role/shard's
pool for its actual simultaneous database users, and keep the total across web
workers, job processes, replicas, and other clients within the database budget.
Two Puma processes with five threads each do not share one five-connection pool;
each process has its own pool. A smaller pool is not automatically a defect.

For a web process with no extra in-process database consumers, use one selected
thread-count value in both configurations. Validate the launch environment
before loading either file: require a positive integer thread count and a worker
configuration supported by the installed Puma version:

```yaml
# config/database.yml (ERB evaluated by Rails)
production:
  adapter: postgresql
  database: storefront_production
  pool: <%= Integer(ENV.fetch("RAILS_MAX_THREADS", "5")) %>
```

```ruby
# config/puma.rb
max_threads = Integer(ENV.fetch("RAILS_MAX_THREADS", "5"))
raise ArgumentError, "RAILS_MAX_THREADS must be positive" unless max_threads.positive?
workers Integer(ENV.fetch("WEB_CONCURRENCY", "2"))
threads max_threads, max_threads
```

Account separately for background threads and other database consumers. Use the
installed Rails connection lifecycle APIs so connections are returned after
work, including errors. Validate checkout latency and total server connections
under representative load before changing production settings.
