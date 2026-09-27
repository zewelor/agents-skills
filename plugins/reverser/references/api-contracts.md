# Reconstruct an application API

Keep the deliverable explicit: protocol documentation, a read-only client, an
application patch and a live experiment have different completion criteria.
Static analysis does not authorize contacting discovered endpoints. Preserve the
user's existing authorization and perform only the selected operations.

## Close the contract's critical gaps

Record each consequential field or rule with its evidence and remaining unknown:

| Boundary | Resolve from the target |
|---|---|
| Transport | Endpoint/environment, HTTP headers, encoding/compression, TLS/client certificate material |
| Authentication | Exact constructor options, mode/padding, encoding, digest bytes/order, nonce/key lifetime, timestamp |
| Request/response | Namespaces, element order where required, required/missing/null behavior, business status and faults |
| Collections | Pagination start/step/end, filter semantics versus the returned document's own classification |
| Authority | What the client knows, what a read response reveals, and what only the server validates |

Do not infer a crypto mode from an upstream default, key encryption from a
filename, or a document category from the list's selection parameter. Preserve
requested filter and returned field separately when they differ. A current
category or UI-wide choice list is not a per-document eligibility list.

## Use independent verification

Distinguish static observation, inference, synthetic behavior, live observation
and user-reported success. A synthetic server built from the client's own
assumptions verifies local transport and error handling; it cannot verify those
assumptions against the target protocol. Mark that limitation explicitly.

For critical authentication details, use independently traced target arguments,
a known vector with separate provenance, or an authorized reference observation.
Fail visibly on unresolved critical options before offering a live-capable client;
a deliberately incomplete prototype may prepare an unsent request if it clearly
identifies the unresolved option. Do not request or retain real credentials to
repair a fixture.

Run subprocess clients with synthetic prompt input in a detached session when
getpass would otherwise read the user's controlling terminal. Preserve hidden
interactive prompting in the production client.

## Report the right completion state

Name which operations and variants are verified. A successful pending-list read
does not prove another response schema, pagination or a mutation. Acceptance of
a requested change is not proof of domain eligibility or final entitlement.
Keep domain-specific rules in the case project, not this reusable reference.

Prefer opt-in, bounded diagnostics containing controlled metadata, status and
field shapes to raw request/response dumps. Preserve a reproducible test artifact
with client hash and provenance; exclude passwords, key material and private rows.
