# FVK Iteration Guidance

Status: constructed, not machine-checked.

## V2 Decision

Keep V1 source code unchanged.

Rationale:

- F-001 and PO-1 through PO-5 show that default `503`/proxy-style failures now refresh the cached leader and retry instead of being returned immediately.
- F-002 and PO-2 show that callers can opt into directly handled statuses through the new overloads.
- F-003 and PO-7 show that broad call-site migration is not required to fix the reported defect and would create method-shape churn in public mocks/overrides.
- F-004 and PO-8 show the only notable implementation assumption, handler reuse, is acceptable for audited public DruidLeaderClient call sites.

## Recommended Future Work

1. Add targeted tests for the new status-retry behavior:
   - default `go(request)` retries after first-attempt `503`;
   - explicit handled statuses return directly;
   - persistent unhandled statuses return the final response;
   - transport-exception retry behavior remains unchanged.

2. Consider targeted production call-site migrations only where there is public evidence that a non-OK status is intentionally handled without internal leader retry. Candidate examples include `404` compatibility paths. This should be a separate patch because it changes method dispatch shape and test mock expectations.

3. If a future caller supplies a stateful `HttpResponseHandler`, re-audit PO-8. The present proof assumes response handlers used with DruidLeaderClient are reusable across status retries.

4. Machine-checking can start from `fvk/mini-druid-leader-client.k` and `fvk/druid-leader-client-spec.k`; the commands are recorded in `fvk/PROOF.md` but intentionally not run.

## Do Not Do

- Do not remove tests based on this proof; it is not machine-checked.
- Do not use hidden test expectations, upstream patches, or benchmark results as evidence.
- Do not edit test files in this benchmark.

## Next Prompt for a Code Generator

If further repair is requested, start from F-003 rather than the already-fixed F-001 path:

> Identify production call sites that intentionally handle non-OK statuses and decide, with public compatibility evidence, whether each should pass an explicit handled-status set to `DruidLeaderClient.go`.

That work is optional for the reported stale-cache defect and was not required for V2.
