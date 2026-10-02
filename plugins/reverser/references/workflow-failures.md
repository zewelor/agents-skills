# Known workflow failures

Use the matching observation to choose the next discriminating check; do not
apply every row to an ordinary task.

| Observation | Next evidence |
|---|---|
| DEX readable, but relevant behavior is absent and Flutter libraries exist | Identify Dart ownership; read [Flutter AOT](flutter-aot.md) |
| Parser profile differs from engine Dart version | Keep the two version meanings separate; validate the selected frontend |
| A guessed constructor default passes a local mock but server rejects auth | Resolve actual target arguments/enum; read [API contracts](api-contracts.md) |
| Filename implies encrypted key | Inspect PEM/container format and parser result; do not infer encryption from name |
| MCP responds, binary import says GUI/PluginTool required | Inspect import capability; stop connection/path retries |
| Global doctor says blocked for tools irrelevant to the task | Check only the selected route, including Compose-provided tools |
| `mise` says `No version is set for shim: droidasc` while the runtime has `mise.toml` | Run from the resolved runtime checkout with an absolute APK path; check the pinned tool entry before treating ASC as unavailable |
| Synthetic test prompts on the human terminal | Detach subprocess session; do not supply a real password to fixtures |
| List filter differs from each returned row's classification | Preserve both; test semantic assumption without overwriting rows |
| Unexpectedly empty xrefs or few decoded instructions | Check index completeness and known function boundaries before asserting absence |
| Several copies disagree or old notes contradict a correction | Identify canonical artifact/hash; mark old assumption superseded |
