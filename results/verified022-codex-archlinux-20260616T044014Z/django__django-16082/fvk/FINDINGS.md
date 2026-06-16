# FINDINGS

Status: constructed, not machine-checked.

## F-001: Pre-V1 Missing Mixed Decimal/Integer MOD Registration

Classification: code bug fixed by V1.

Evidence: E1, E2, E3; Proof Obligations PO-002, PO-003, PO-004.

Input:

```text
connector = Combinable.MOD
lhs_type = DecimalField
rhs_type = IntegerField
```

Observed before V1: `_resolve_combined_type()` had no mixed numeric MOD row, so
it returned `None`; `CombinedExpression._resolve_output_field()` then raised
`FieldError`.

Expected: `DecimalField`.

V1 status: fixed. Adding `Combinable.MOD` to the mixed numeric connector tuple
registers the existing `DecimalField, IntegerField -> DecimalField` row for MOD.

## F-002: Mixed Numeric MOD Is a Table Family, Not a Single Pair

Classification: completeness check passed by V1.

Evidence: E5; Proof Obligations PO-002, PO-005.

The public issue names Decimal/Integer, but the implementation already groups
mixed numeric result promotion as a family of rows under each connector. A
hand-coded fix for only `DecimalField % IntegerField` would leave
`IntegerField % FloatField` inconsistent with the table's own family structure.

V1 status: passed. Adding `Combinable.MOD` to the connector tuple registers all
existing mixed numeric rows for MOD while preserving the table shape.

## F-003: Mixed Numeric POW and Decimal/Float Rows Are Out of Scope

Classification: no code change recommended.

Evidence: E6; Proof Obligations PO-006, PO-007.

The source explicitly states that missing combinations result in `FieldError` by
design. The public issue is about MOD, and the existing mixed numeric table does
not include Decimal/Float rows for the other arithmetic connectors.

V1 status: correct to leave unchanged. Extending mixed numeric POW or adding
Decimal/Float promotion would be unrelated behavior expansion.

## F-004: No Public Compatibility Issue

Classification: compatibility confirmed.

Evidence: `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`; Proof Obligation PO-008.

No public symbol signature, dispatch shape, or callsite protocol changed. The
only source change is one additional connector in an existing table.

V1 status: no further code change.

## Proof-Derived Findings From `/verify`

The constructed proof produced no failed or ambiguous adequacy entries. The only
residual risk is the FVK honesty gate: the K claims and proof are constructed,
not machine-checked, because this task forbids running `kompile` or `kprove`.
