# Formal Spec in English

This file paraphrases the nontrivial K claims in `http-response-spec.k`.

## Claim MAKE-BYTES-MEMORYVIEW

For every payload and charset, evaluating `makeBytes(memoryview(payload), charset)` terminates with the bytes value containing exactly `payload`.

Intent coverage: I-005, supported by E-004 through E-006.

## Claim CONTENT-MEMORYVIEW

For every payload and charset, assigning `memoryview(payload)` to regular `HttpResponse.content` terminates with the response container holding one bytestring whose payload is exactly `payload`.

This claim includes the branch selection obligation: memoryview is not consumed as iterable chunk content.

Intent coverage: I-003 and I-004, supported by E-001, E-002, E-005, and E-008.

## Claim CONTENT-BYTES-FRAME

For every bytes payload and charset, assigning bytes to regular `HttpResponse.content` terminates with the response container holding that same payload.

Intent coverage: I-002 and I-006, supported by E-003.

## Claim CONTENT-STRING-FRAME

For every text payload and charset, assigning text to regular `HttpResponse.content` terminates with the response container holding the charset-encoded text payload.

Intent coverage: I-001 and I-006, supported by E-003.

## Claim CONTENT-ITERABLE-FRAME

For every non-scalar iterable value represented as a list of chunks, assigning it to regular `HttpResponse.content` terminates with the response container holding the join of `makeBytes(chunk, charset)` for each chunk in order.

Intent coverage: I-006 and E-009.

## No Loop Circularities

The audited source slice contains no loops. The proof has no circularity claim; it relies on branch symbolic execution and frame obligations.
