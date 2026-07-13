# Runtime Trace Investigation

Use saved traces to prove which trigger, condition branch, and action path ran.
Treat one trace as evidence for that run only; list paths that still require a
real event or controlled test.

## Safety boundary

- Read `.deployment_info` and select the exact current runtime target first.
- Prefer the Home Assistant API or UI when it exposes the required trace.
- Inspect `.storage/trace.saved_traces` read-only only when API access is not
  available. Never edit, copy back, or commit it.
- Never dump a complete trace. It can contain locations, messages, service
  data, state attributes, and other sensitive context.
- Do not trigger an automation, change a helper, or call a service without
  explicit authorization.

## Workflow

1. Map the YAML `id` to the trace key `automation.<id>` or `script.<id>`.
2. List only trace keys and counts before selecting the relevant item:

   ```bash
   jq -r '.data | to_entries[] | [.key, (.value | length)] | @tsv' \
     <config-path>/.storage/trace.saved_traces
   ```

3. Inspect the selected record's field names if its schema is unfamiliar;
   never solve a schema mismatch by dumping the whole record:

   ```bash
   jq --arg key 'automation.<id>' \
     '.data[$key][-1] | {top: keys, short: (.short_dict | keys), extended: (.extended_dict | keys)}' \
     <config-path>/.storage/trace.saved_traces
   ```

4. Read the high-level outcome without variables or state attributes:

   ```bash
   jq --arg key 'automation.<id>' \
     '.data[$key][-1].short_dict | {last_step, state, script_execution, timestamp, trigger}' \
     <config-path>/.storage/trace.saved_traces
   ```

5. Extract only the needed path results. Start with booleans, choices, wanted
   states, timestamps, and errors. Include an actual state only when needed and
   non-sensitive; never print person/device-tracker locations or attributes.
6. Correlate the executed trace path with the blueprint or automation source.
   Report the trigger, selected branch, finish/error state, and untested paths.

## Blueprint checks

When an automation references a blueprint that is absent from the repository,
check the production blueprint path read-only before calling it broken. Verify
its `source_url`, compare a cryptographic hash with any proposed tracked copy,
and distinguish Home Assistant-provided `homeassistant/` blueprints from custom
ones. A loaded, successful trace proves runtime availability, while repository
tracking proves reproducibility; require both for closure.
