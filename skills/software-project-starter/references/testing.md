# Testing and verification decisions

Map the first useful scenario and important failure modes before implementation.
Identify uncovered contracts before selecting a test tool. Prefer realistic E2E
evidence for complex flows; retain focused tests that catch failures those flows
do not cover. Treat a startup smoke as startup evidence, not whole-product E2E.

## Evaluate the methods

Make a brief, risk-based choice: use, pilot, or skip the methods that could help.
For a method worth trying, name one concrete property or risk, its likely benefit
and cost, and the smallest useful scope. Omit methods with no credible role; do
not fill out a matrix just to account for every method.

| Method | Evaluate when | Account for |
|---|---|---|
| E2E / integration | A user flow crosses real components or persistence boundaries | Representative data, error paths, environment setup, reproducible evidence |
| Property-based testing | Parsing, normalization, geometry, transformations, broad input combinations | Independent properties/oracles, useful generators, shrinking, runtime |
| Stateful / model-based testing | Correctness depends on sequences of operations | Action model, reference state, isolation, failure reproduction |
| Formal methods, such as TLA+ | Expensive design errors involve coordination, concurrent states, retries, or progress guarantees | Model scope, explicit assumptions, learning cost, state-space growth, model/code drift |

## Choose meaningful properties

- Check round-trip equivalence under the actual serialization contract,
  idempotence of normalization, conservation rules, or an independent oracle.
- Generate valid boundary cases and invalid inputs with specified error behavior.
  Avoid copying the implementation into assertions or testing only lack of crashes.
- For sequences, compare observable behavior with a simpler model; include
  repeated requests and failures where the contract requires them.
- Model safety and progress separately. State fairness and availability
  assumptions needed for progress; check what happens on cancellation and retry.
- For Python, consider [Hypothesis](https://hypothesis.readthedocs.io/en/latest/)
  and its [stateful testing](https://hypothesis.readthedocs.io/en/latest/stateful.html).
  For Go, consider built-in fuzzing where it fits the property. Reuse the project's
  installed tools before adding a new library; verify other language APIs in docs.
- Distinguish [TLA+ model checking and proof tools](https://lamport.azurewebsites.net/tla/tools.html).
  Treat passing generated tests as finite evidence; treat a checked model as
  evidence for that model, assumptions, and configuration, not automatic proof
  that the implementation is correct.

Use the [property catalog](https://github.com/trailofbits/skills/tree/main/plugins/property-based-testing)
as inspiration; select properties from the project's contracts, not from a fixed
ranking or blanket rule that excludes all integration testing.

## Bound the pilot and retain evidence

Choose one important function or state machine and set a time budget before
trying a new method. Record discovered bugs or ambiguous contracts, setup effort,
CI time, and ongoing maintenance. Decide whether the risk reduction justifies
keeping or expanding it; case counts alone do not establish value.

Specify a reproducible command and artifact for complex E2E scenarios: fixture
outputs, structured results, or screenshots as appropriate. Exercise realistic
success, boundary, and failure paths; control external services through fixtures
or explicit test environments without pretending a stub proves the real boundary.

Write justified isolated tests before implementing the behavior. Add a regression
test for an existing bug only when current behavior tests leave a real gap.
Keep focused development checks fast; run the complete required E2E suite at the
end. Preserve required security, schema, parser, and recovery coverage even when
an E2E suite misses it. Report skipped checks and their implications explicitly.
