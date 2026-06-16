# PROOF

Status: constructed, not machine-checked.

## Claim Summary

The constructed proof covers the output-field inference table for mixed numeric
MOD expressions:

- Decimal/Integer MOD resolves to Decimal in both operand orders.
- Integer subclasses paired with Decimal also resolve to Decimal.
- Integer/Float MOD resolves to Float in both operand orders, preserving the
  existing mixed numeric family.
- Mixed numeric POW remains unsupported.

The formal claims are in `fvk/combined-expression-spec.k`; the reduced semantics
are in `fvk/mini-combined-expression.k`.

## Source-Level Proof Sketch

1. `_connector_combinations` contains a dictionary for mixed numeric operations.
   V1 adds `Combinable.MOD` to that dictionary's connector tuple.

2. The registration loop iterates through every connector and every row in the
   dictionary, calling `register_combinable_fields(lhs, connector, rhs, result)`.
   Therefore, for connector `Combinable.MOD`, it appends:

   - `IntegerField, DecimalField -> DecimalField`
   - `DecimalField, IntegerField -> DecimalField`
   - `IntegerField, FloatField -> FloatField`
   - `FloatField, IntegerField -> FloatField`

3. `_resolve_combined_type("%%", DecimalField, IntegerField)` retrieves the MOD
   combinator list and scans it in registration order. Same-type rows do not
   match both operands. The mixed row
   `DecimalField, IntegerField -> DecimalField` does match, so the function
   returns `DecimalField`.

4. The reversed input follows the same argument with the row
   `IntegerField, DecimalField -> DecimalField`.

5. For integer subclasses, Python `issubclass()` makes the integer side satisfy
   the registered `IntegerField` row, so the same Decimal result follows.

6. `CombinedExpression._resolve_output_field()` raises `FieldError` only when
   `_resolve_combined_type()` returns `None`. For the mixed MOD cases above it
   returns a field class, so `_resolve_output_field()` returns an instance of
   that class.

7. V1 does not change the row list or add `Combinable.POW` to the mixed numeric
   connector list. Unsupported combinations outside the issue remain missing by
   design.

## K Proof Sketch

The K model represents the table-expanded resolver as `resolve(C, L, R)`.

The claims reduce by direct rewrite:

- `resolve(mod, decimal, integer)` rewrites via the mixed numeric connector rule
  and Decimal/Integer row to `some(decimal)`.
- `resolve(mod, integer, decimal)` rewrites via the symmetric row to
  `some(decimal)`.
- `resolve(mod, decimal, integerSub)` uses `isIntegerFamily(integerSub) => true`
  and rewrites to `some(decimal)`.
- Integer/Float MOD claims rewrite to `some(float)`.
- Mixed Decimal/Integer POW rewrites to `noType` because
  `mixedNumericConnector(pow) => false` and the model includes explicit
  unsupported POW rules.

There are no loops, recursion, or circularities. The proof is finite symbolic
execution over table membership and boolean side conditions.

## Residual Risk

This proof is constructed only. It has not been machine-checked because the task
forbids running K tooling. The trusted base is the adequacy of the reduced model:
it intentionally abstracts away SQL execution and models only the resolver table
and `issubclass()` family behavior, which is the issue's observable.

## Reproduce Later

Do not run these commands in this task. They are the recorded machine-check
commands for a later environment:

```sh
kompile fvk/mini-combined-expression.k --backend haskell
kast --backend haskell fvk/combined-expression-spec.k
kprove fvk/combined-expression-spec.k
```

Expected machine-check result after installing K: `kprove` returns `#Top`.
