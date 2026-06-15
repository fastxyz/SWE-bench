# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source-code defect in the V1 patch and did not justify broadening the change beyond memoryview handling for regular `HttpResponse` content and shared `make_bytes()` conversion.

## Trace to Findings and Proof Obligations

F-001 traces to PO-001 and PO-002. PO-001 requires `make_bytes(memoryview_payload)` to return `bytes(memoryview_payload)`, and PO-002 requires the regular `HttpResponse.content` setter to treat top-level memoryview as scalar content rather than iterating it. V1 satisfies both with the `memoryview` branch in `make_bytes()` and the `memoryview` exclusion in the iterable condition.

F-002 explains why I kept both V1 edits. A `make_bytes()`-only change would leave the top-level memoryview path vulnerable to iterable consumption before `make_bytes()` receives the original object. That proof-derived localization confirms the setter edit is not incidental.

F-003 traces to PO-003, PO-004, and PO-005. V1 leaves the bytes branch, string branch, and ordinary iterable chunk path intact, preserving behavior the issue identifies as correct or the source comment identifies as intended.

F-004 records the decision not to add `bytearray` handling. Although `BinaryField` documentation mentions `bytearray`, the issue and public hint specifically require memoryview support. Changing bytearray would be a broader behavior change not required by any proof obligation in this run.

F-005 records the decision not to reinterpret top-level `StreamingHttpResponse(memoryview(...))` as one chunk. PO-001 covers memoryview chunks that pass through `make_bytes()`, but the regular-response issue does not impose a proof obligation on top-level streaming memoryview input.

PO-006 supports the compatibility decision: no signatures changed, no `make_bytes()` overrides were found in `repo/django`, and the patch does not alter subclass dispatch shape.

PO-007 records the honesty gate. I did not run tests, Python snippets, `kompile`, or `kprove`; the FVK proof is constructed, not machine-checked.

## Artifacts

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK adequacy and formal artifacts are:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-response.k`
- `fvk/http-response-spec.k`

No additional source edits were made during the FVK phase.
