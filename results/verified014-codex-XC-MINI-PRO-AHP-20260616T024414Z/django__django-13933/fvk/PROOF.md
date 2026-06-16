# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/model-choice-field-spec.k` and use the semantics
in `fvk/mini-django-forms.k`.

There are no loops or recursive functions in the audited unit, so no
circularity claim is needed.

## Proof sketch

1. `EMPTY-VALUE`: symbolic execution applies the empty-value rule for
   `modelChoiceToPython(emptyValue())` and reaches `ok(emptyValue())`. This
   discharges PO-1 and PO-4 for the empty branch.

2. `VALID-SUBMITTED`: symbolic execution applies the submitted-key rule, then
   the `queryGet()` success rule because the queryset map contains the key. The
   result is `ok(OBJ)`. This discharges PO-1 and PO-4 for valid submitted input.

3. `VALID-MODEL-INSTANCE`: the model-instance rule converts the instance to the
   same lookup key used by the submitted-key path. If the key is present, the
   same success proof as step 2 applies. This preserves the existing
   model-instance behavior.

4. `INVALID-SUBMITTED`: symbolic execution applies the submitted-key rule, then
   the `queryGet()` missing-key rule under `notBool(K in_keys(QS))`. The
   `invalidChoice()` rule constructs
   `validationError("invalid_choice", render(MSG, submitted(K)), "value" |->
   submitted(K))`. With the default message, rendering includes `K`. This
   discharges PO-2 and PO-3 for missing submitted keys.

5. `INVALID-MODEL-KEY`: symbolic execution first converts `modelInstance(K)` to
   `submitted(K)`, then follows the missing-key branch. The constructed error
   contains `params['value']` equal to the lookup key. This discharges PO-2 and
   PO-5.

6. `INVALID-BAD-TYPE`: symbolic execution routes `badType(K)` to the same
   invalid-choice constructor used for `ValueError` and `TypeError` paths. The
   constructed error contains `params['value']` equal to the rejected value.
   This discharges PO-2 for conversion/type failures.

7. Frame condition: V1 edits neither signatures nor success branches. The
   compatibility audit discharges PO-6.

## Machine-check commands not run

The current task forbids running K tooling. These are the commands to run in a
future environment:

```sh
kompile fvk/mini-django-forms.k --backend haskell
kast --backend haskell fvk/model-choice-field-spec.k
kprove fvk/model-choice-field-spec.k
```

Expected machine-check result: `kprove` returns `#Top` for all claims.

## Test guidance

Do not remove tests based on this constructed proof alone. After
machine-checking, point tests for invalid `ModelChoiceField` choices with
`%(value)s` become redundant with PO-2 and PO-3. Keep integration tests,
template escaping tests, tests for custom error messages without placeholders,
and tests for public form/model wiring.

