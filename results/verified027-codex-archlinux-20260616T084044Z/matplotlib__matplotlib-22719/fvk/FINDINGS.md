# FVK Findings

Status: constructed, not machine-checked.

## Findings from formalization

### F-001: Empty conversion was classified as numeric-like by vacuous truth

- Input: a category-unit axis with known units, then `ax.plot([], [])` or
  direct `ax.convert_xunits([])`.
- Observed before V1: `all(...)` over empty `values` made `is_numlike` true,
  so `StrCategoryConverter.convert` emitted the deprecated numeric pass-through
  warning and could become a `ConversionError` when warnings were errors.
- Expected: empty data converts as an empty categorical result with no numeric
  pass-through warning.
- Evidence: E1-E5.
- Classification: code bug; resolved by V1 guard `if values.size and
  is_numlike`.
- Proof obligations: PO-1, PO-2, PO-3, PO-4.

### F-002: Empty `UnitData.update` could emit an all-convertible log by vacuity

- Input: `UnitData.update([])` or converter fallback to `unit.update(values)`
  with empty normalized data.
- Observed before V1: `convertible` remained true because no values were
  inspected, so the all-strings-parseable-as-number/date message could be
  emitted for empty data.
- Expected: no all-convertible log unless at least one value was inspected.
- Evidence: E6 and the same vacuous-truth mechanism as E10.
- Classification: code bug; resolved by V1 guard `if data.size and
  convertible`.
- Proof obligations: PO-5, PO-6.

### F-003: Non-empty numeric pass-through remains intentionally deprecated

- Input: `StrCategoryConverter.convert([1.0, 2.0], unit, axis)`.
- Observed with V1: the `values.size and is_numlike` guard is true, so the
  existing warning path remains reachable.
- Expected: preserve public-test behavior expecting `MatplotlibDeprecationWarning`.
- Evidence: E7.
- Classification: frame condition; no code change beyond V1.
- Proof obligation: PO-2.

### F-004: Non-empty invalid mixed categorical data remains rejected

- Input: `StrCategoryConverter.convert(["A", 2], unit, axis)`.
- Observed with V1: `is_numlike` is false, so conversion still reaches
  `UnitData.update`, which rejects non-string/non-bytes values.
- Expected: preserve public-test behavior expecting `TypeError`.
- Evidence: E8.
- Classification: frame condition; no code change beyond V1.
- Proof obligation: PO-4.

## Proof-derived findings from `/verify`

No additional production-code defect was found. The proof obligations require
exactly the two V1 guards and no API or callsite changes. The constructed proof
is not machine-checked, so test removal is not recommended. Existing tests for
mapping order, mixed-type rejection, and plotting integration remain valuable
because the mini-category abstraction intentionally does not prove full NumPy,
mapping-order, or artist-drawing semantics.
