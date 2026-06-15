# FINDINGS.md

Status: constructed, not machine-checked.

## F-001: V0 rejected a final registered lookup in `Meta.ordering`

- Classification: code bug in the pre-V1 implementation.
- Evidence: I-001 and I-002 in `SPEC.md`.
- Input: `ordering = ('supply__product__parent__isnull',)` where `supply`, `product`, and `parent` are resolved foreign key fields and `isnull` is registered as a lookup on the final foreign key field.
- Observed before V1: `_check_ordering()` reached the unresolved `isnull` segment and tested only `fld.get_transform('isnull')`, then emitted `models.E015`.
- Expected: no `models.E015` for the ordering component, because the unresolved final segment is a registered lookup and the issue states the corresponding `order_by()` path works.
- Status after FVK: resolved by V1. PO-1 and claims `REPORTED-CASE` / `FINAL-LOOKUP-VALID` cover this.

## F-002: The fix must not validate arbitrary unresolved middle segments

- Classification: regression risk controlled by V1.
- Evidence: I-005 in `SPEC.md`.
- Input: a path with a resolved field prefix followed by a lookup-like unresolved segment that is not the final segment, e.g. `parent__isnull__bogus`.
- Bad alternative: accepting `fld.get_lookup(part)` at any unresolved segment would allow `isnull` to pass before `bogus` is examined as if it were a transform chain.
- Expected: a non-final unresolved segment must still be valid only as a transform; a lookup is valid only at the final unresolved segment.
- Status after FVK: controlled by V1's `index == len(parts) - 1` guard. PO-3 and claim `NONFINAL-LOOKUP-INVALID` cover this.

## F-003: Registered transforms remain valid

- Classification: compatibility obligation confirmed.
- Evidence: I-004 in `SPEC.md`.
- Input: `ordering = ('test__lower',)` with `lower` registered as a transform on the `test` field.
- Expected: no `models.E015`; this behavior existed before the issue and must remain.
- Status after FVK: preserved by V1 because `get_transform(part)` is still accepted independently of lookup handling. PO-2 and claim `TRANSFORM-STILL-VALID` cover this.

## F-004: No public API compatibility break found

- Classification: compatibility check.
- Evidence: I-006 and `PUBLIC_COMPATIBILITY_AUDIT.md`.
- Input: callers of `Model._check_ordering()` and Django's check framework expecting a list of `checks.Error` objects.
- Observed after V1: no signature, return type, check ID, or error message shape changed.
- Expected: public check framework behavior remains compatible except that the previously false-positive lookup case no longer emits `models.E015`.
- Status after FVK: confirmed by PO-5.

## F-005: Proof and test results are not machine-checked here

- Classification: verification environment limitation.
- Evidence: task instruction forbids running tests, Python, or K tooling.
- Input: FVK commands listed in `SPEC.md` and `PROOF.md`.
- Observed: commands were written but not executed.
- Expected: later machine checking with `kompile`/`kprove` should return `#Top`; project tests should be run in an environment that allows execution.
- Status after FVK: residual risk only; it does not justify source changes.
