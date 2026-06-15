# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Memoryview Byte Conversion

Claim: `MAKE-BYTES-MEMORYVIEW`

Requirement: `HttpResponseBase.make_bytes(memoryview_payload)` returns `bytes(memoryview_payload)`.

Evidence: E-004, E-005, E-006.

Discharge status: discharged by V1. The patched `make_bytes()` checks `isinstance(value, memoryview)` before the string fallback and returns `bytes(value)`.

## PO-002: Top-Level Memoryview Branch Selection

Claim: `CONTENT-MEMORYVIEW`

Requirement: `HttpResponse.content = memoryview_payload` must call `make_bytes(memoryview_payload)` as a scalar value, not iterate through the memoryview.

Evidence: E-001, E-002, E-005.

Discharge status: discharged by V1. The content setter excludes `memoryview` from the ordinary iterable branch, so the `else` branch calls `make_bytes()` on the original memoryview.

## PO-003: Bytes Behavior Frame

Claim: `CONTENT-BYTES-FRAME`

Requirement: Existing bytes content remains unchanged.

Evidence: E-003.

Discharge status: discharged by V1. The bytes branch in `make_bytes()` is unchanged, and bytes remain excluded from iterable consumption.

## PO-004: String Behavior Frame

Claim: `CONTENT-STRING-FRAME`

Requirement: Existing string content remains charset encoded.

Evidence: E-003.

Discharge status: discharged by V1. The string branch in `make_bytes()` is unchanged, and strings remain excluded from iterable consumption.

## PO-005: Ordinary Iterable Frame

Claim: `CONTENT-ITERABLE-FRAME`

Requirement: Existing non-memoryview iterables continue to be consumed as chunks.

Evidence: E-009 and I-006.

Discharge status: discharged by V1. The iterable condition still accepts non-`bytes`, non-`str`, non-`memoryview` iterables, preserving the chunk-join path.

## PO-006: Compatibility

Claim source: `PUBLIC_COMPATIBILITY_AUDIT.md`

Requirement: The fix must not introduce a public signature, override, or dispatch incompatibility.

Evidence: public source scan of `repo/django`.

Discharge status: discharged. No signature changed, no `make_bytes()` override was found in `repo/django`, and the changed setter branch preserves the public call shape.

## PO-007: FVK Honesty Gate

Requirement: Do not claim machine-checked proof or test redundancy because execution and K tooling are forbidden.

Evidence: task instructions and FVK verify honesty gate.

Discharge status: discharged by labeling artifacts constructed, not machine-checked, and by not running tests, Python, `kompile`, or `kprove`.
