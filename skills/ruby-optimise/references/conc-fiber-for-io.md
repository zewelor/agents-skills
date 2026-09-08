---
title: Use an Existing Scheduler for Bounded I/O
tags: conc, fiber, io
---

## Use an Existing Scheduler for Bounded I/O

Use fibers only with a scheduler and I/O libraries that cooperate with it.
Read the locked versions of the scheduler and HTTP/database client before
writing code; do not introduce Async or another runtime solely because this
reference mentions fibers.

1. Identify I/O wait in the measured path. Keep CPU-heavy work outside the
   scheduler's thread when it would block all tasks.
2. Use the installed executor's bounded concurrency and backpressure controls.
   Do not launch one fiber for every input without a limit.
3. Preserve input/result ordering and the caller's return type. Await the
   executor's result; do not return a Task where an Array was returned before.
4. Bound connection and read waits using the client's supported timeout API.
5. Consume or close every response body and close the client in `ensure`.
6. Propagate failures and wait for or cancel outstanding work using the
   executor's documented lifecycle. Do not replace a failed batch with `[]`.
7. Test empty input, a failed request, timeouts, ordering, and resource cleanup
   with a local fake endpoint before comparing representative throughput.

Keep a bounded thread implementation if it already meets the requirement.
Do not promise a fixed memory footprint per fiber or thread across runtimes.
