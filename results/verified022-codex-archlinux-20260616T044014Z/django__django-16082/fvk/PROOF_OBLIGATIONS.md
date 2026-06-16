# PROOF_OBLIGATIONS

Status: constructed, not machine-checked.

## PO-001: Adequacy of Intent

The formal claims must express the public issue intent, not merely current
candidate behavior.

Discharge: `fvk/INTENT_SPEC.md`, `fvk/FORMAL_SPEC_ENGLISH.md`, and
`fvk/SPEC_AUDIT.md` align the claims with E1-E3. No adequacy item is marked fail
or ambiguous.

## PO-002: Mixed Numeric MOD Rows Are Registered

Given V1's connector tuple includes `Combinable.MOD`, the registration loop must
append the four existing mixed numeric rows to `_connector_combinators["%%"]`.

Discharge: finite expansion of `_connector_combinations` at lines 523-537 of
`expressions.py`. The same rows that already apply to add/sub/mul/div now apply
to MOD.

## PO-003: Decimal/Integer MOD Resolves to Decimal

For `connector = MOD` and exact field classes `DecimalField, IntegerField`, the
resolver must return `DecimalField` in either order.

Discharge: in `_resolve_combined_type()`, earlier same-type MOD rows fail their
`issubclass()` checks for mixed operands; the registered mixed row then succeeds
and returns `DecimalField`.

## PO-004: Integer Subclasses Are Covered

For `connector = MOD`, `DecimalField` paired with an `IntegerField` subclass must
also resolve to `DecimalField`.

Discharge: `_resolve_combined_type()` uses `issubclass(lhs_type, row_lhs)` and
`issubclass(rhs_type, row_rhs)`, so the `IntegerField` row covers subclasses such
as `AutoField`, `BigIntegerField`, `SmallIntegerField`, and positive variants.

## PO-005: Integer/Float MOD Resolves Consistently With the Mixed Numeric Table

For `connector = MOD`, Integer/Float rows must resolve to `FloatField` in either
order because V1 applies MOD to the whole existing mixed numeric row family.

Discharge: same finite table expansion as PO-002.

## PO-006: Unsupported Mixed Numeric Combinations Remain Unsupported

Mixed numeric POW and Decimal/Float rows absent from the pre-existing mixed
numeric table must remain absent.

Discharge: V1 only adds `Combinable.MOD` to the connector list. It does not add
`Combinable.POW` to that list and does not change the row list.

## PO-007: `CombinedExpression._resolve_output_field()` Returns an Instance

Once `_resolve_combined_type()` returns a non-`None` class for mixed numeric MOD,
`CombinedExpression._resolve_output_field()` must instantiate and return it,
rather than raising `FieldError`.

Discharge: existing control flow raises only when `combined_type is None`;
otherwise it executes `return combined_type()`.

## PO-008: Public Compatibility

The repair must not alter public signatures, caller protocols, or test files.

Discharge: V1 changes only `_connector_combinations` data. The compatibility
audit found no public callsite or override issue.

## Machine-Check Commands

Do not run these in this task. They are recorded for later machine checking:

```sh
kompile fvk/mini-combined-expression.k --backend haskell
kast --backend haskell fvk/combined-expression-spec.k
kprove fvk/combined-expression-spec.k
```
