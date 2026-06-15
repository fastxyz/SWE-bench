# PROOF

Status: constructed, not machine-checked.

## What is proved

For the abstract input classes in `fvk/mini-decimal-field.k`, the candidate `DecimalField.to_python()` behavior satisfies the intent-derived contract in `fvk/SPEC.md`:

- valid conversion inputs return converted decimal values;
- existing invalid syntax still raises Django `ValidationError`;
- dictionary/type-error conversion failures now raise Django `ValidationError`;
- malformed/value-error conversion failures also raise Django `ValidationError`;
- the public signature and valid-input behavior are preserved.

## Proof sketch

There are no loops, recursive calls, mutable stores, or arithmetic verification conditions in the audited source fragment. Each claim is discharged by symbolic execution of one or two rewrite steps in the mini semantics.

1. `none`: `toPython(none, PREC)` rewrites directly to `returnNone`.
2. `floatInput(F)`: `toPython(floatInput(F), PREC)` rewrites directly to `returnDecimal(decimalFromFloat(F, PREC))`.
3. `validInput(D)`: `toPython(validInput(D), PREC)` rewrites to `handle(decimalDecimal(validInput(D)), validInput(D))`; `decimalDecimal(validInput(D))` simplifies to `ok(decimal(D))`; `handle(ok(decimal(D)), validInput(D))` rewrites to `returnDecimal(decimal(D))`.
4. `invalidSyntaxInput`: conversion simplifies to `raises(invalidOperation)`; `handle(raises(invalidOperation), invalidSyntaxInput)` rewrites to `validationError(invalidSyntaxInput)`.
5. `dictInput`: conversion simplifies to `raises(typeError)`; `handle(raises(typeError), dictInput)` rewrites to `validationError(dictInput)`.
6. `malformedTupleInput`: conversion simplifies to `raises(valueError)`; `handle(raises(valueError), malformedTupleInput)` rewrites to `validationError(malformedTupleInput)`.
7. `otherExceptionInput`: conversion simplifies to `raises(otherError)`; `handle(raises(otherError), otherExceptionInput)` rewrites to `rawException(otherError)`, preserving the targeted scope of the V1 edit.

By Transitivity, each starting configuration in `decimal-field-spec.k` reaches the claimed final outcome. No circularity rule is needed.

## Adequacy and compatibility

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases every K claim. `fvk/SPEC_AUDIT.md` compares those claims with `fvk/INTENT_SPEC.md` and marks all obligations pass. `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` found no unhandled callsite, override, or public API change.

## Reproduce the machine check later

These commands are recorded but were not run in this session:

```sh
cd fvk
kompile mini-decimal-field.k --backend haskell
kast --backend haskell decimal-field-spec.k
kprove decimal-field-spec.k
```

Expected result after a successful machine check: `kprove` returns `#Top` for all claims.

## Test-redundancy recommendation

No tests were edited. If the K claims are machine-checked later, the public `DecimalField.to_python()` unit assertions for valid integer/string conversion, float conversion, and invalid string validation are proof-covered in-domain points. Keep integration, database-backend, performance, and any out-of-domain tests because this proof covers only the unit conversion decision.

## Residual risk

- Constructed, not machine-checked.
- The mini semantics abstracts Python's decimal internals and proves only the exception-normalization decision relevant to this issue.
- Tests, Python, and K tooling were not run, per benchmark instructions.
