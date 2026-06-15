# Iteration Guidance

Status: V2 equals V1 for source code. No further code edit is recommended for this issue.

## Decision

Keep the V1 patch unchanged.

Rationale:

- F-001 confirms the original symptom is addressed.
- F-002 confirms both V1 edits are necessary and jointly sufficient for the regular `HttpResponse(memoryview(...))` path.
- F-003 confirms the public frame conditions for string, bytes, and ordinary iterables.
- F-004 rejects broadening to bytearray because the public issue evidence does not require it.
- F-005 rejects changing top-level streaming memoryview behavior because it is outside the regular `HttpResponse` issue and the streaming API's chunk-iterator contract.

## Next Code Generator Prompt

No source regeneration needed. If a future task wants broader bytes-like support, ask separately:

Should regular `HttpResponse` treat `bytearray` as scalar bytes-like content, matching `bytes(bytearray_value)`, or preserve the current iterable chunk behavior?

Should `StreamingHttpResponse(memoryview(...))` treat the memoryview as a single chunk, or is a top-level memoryview still an iterable of chunks under the streaming API?

## Test Guidance

Do not edit tests in this task. In a normal development flow, add focused tests for the four cases listed in `PROOF.md`: constructor memoryview content, content assignment, `write()`, and streaming memoryview chunks.

Do not remove existing tests based on this FVK run. The proof is constructed, not machine-checked.
