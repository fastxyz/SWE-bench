# FVK Notes

## Decision

V1 stands unchanged. No additional source edit is needed after the FVK audit.

## Trace to Findings and Proof Obligations

F-001 identifies the original bug: mixed Decimal/Integer MOD had no registered
type row and therefore fell through to `FieldError`. PO-002 and PO-003 show that
V1 registers the existing mixed numeric Decimal/Integer rows for
`Combinable.MOD`, so both operand orders now resolve to `DecimalField`.

F-002 checks whether the fix should be narrower than V1. PO-005 shows that adding
`Combinable.MOD` to the existing mixed numeric connector family also registers
Integer/Float rows for MOD. That is preferable to a one-off Decimal/Integer
special case because the public issue describes mixed numeric MOD behavior "like
other mathematical operators," and the code already expresses that promotion as
a table family.

F-003 checks whether the fix should be broader than V1. PO-006 shows that mixed
numeric POW and Decimal/Float combinations remain absent from the existing mixed
numeric table. The source comment says missing combinations raise `FieldError`
by design, and the public issue does not require expanding those combinations.
No broader source edit is justified.

F-004 and PO-008 confirm compatibility: the repair changes only table data and
does not alter public signatures, dispatch shape, or test files.

PO-004 and PO-007 cover propagation from the table entry to the reported
observable. The `issubclass()` checks cover integer-field subclasses, and once
`_resolve_combined_type()` returns a non-`None` field class,
`CombinedExpression._resolve_output_field()` returns an instance instead of
raising `FieldError`.

## Artifacts

The FVK artifacts are under `fvk/`. The formal core is:

- `fvk/mini-combined-expression.k`
- `fvk/combined-expression-spec.k`

The proof is constructed, not machine-checked. Per the task constraints, I did
not run tests, Python, `kompile`, `kast`, or `kprove`.
