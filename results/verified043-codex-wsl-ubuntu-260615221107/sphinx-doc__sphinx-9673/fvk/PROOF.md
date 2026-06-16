# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove`
commands were executed.

## What Is Proved

For the modeled return-type augmentation behavior of
`augment_descriptions_with_types()`:

- a `returns` field is a documented return description;
- a `return` field remains a documented return description;
- if a return annotation exists and no `rtype` exists, either return-description
  spelling causes one `rtype` field to be added;
- existing `rtype` suppresses duplicate insertion;
- missing return description or missing return annotation suppresses insertion.

## Formal Artifacts

- `fvk/mini-autodoc-fieldlist.k`: mini semantics over field-list tokens.
- `fvk/autodoc-typehints-spec.k`: K claims for the return augmentation contract.

## Proof Sketch

1. Symbolically evaluate `augmentReturn(fields, hasReturnAnnotation, annotation)`
   in the mini semantics.
2. Use the recursive definition of `hasReturnDescription(fields)`:
   `returnField` and `returnsField` both rewrite to `true` for the canonical
   return-description marker.
3. Use the recursive definition of `hasReturnType(fields)`: `rtypeField` rewrites
   to `true`; other fields defer to the tail.
4. Apply the first `augmentReturn` rule when all three positive conditions hold:
   return annotation exists, return description exists, and return type does not
   exist. The result is `addRtype(annotation)`.
5. Apply the second `augmentReturn` rule when no annotation exists, no return
   description exists, or a return type already exists. The result is `noRtype`.
6. The two alias-specific claims instantiate the general add claim with
   `returnsField ; FS` and `returnField ; FS`. The no-duplicate and missing-input
   claims instantiate the negative rule.

## Verification Conditions

- VC-1: `hasReturnDescription(returnsField ; FS) = true`.
- VC-2: `hasReturnDescription(returnField ; FS) = true`.
- VC-3: `hasReturnType(rtypeField ; FS) = true`.
- VC-4: If `not hasReturnType(FS)`, then
  `not hasReturnType(returnsField ; FS)` and
  `not hasReturnType(returnField ; FS)`.
- VC-5: The negative `augmentReturn` rule covers the complement of the positive
  append condition.

All VCs are structural rewrites or Boolean simplifications in the mini semantics.

## Adequacy

The model preserves the defect axis: `returnField` and `returnsField` are distinct
inputs, and the observable output distinguishes `addRtype(annotation)` from
`noRtype`. A pre-V1 model without the `returnsField` case in
`hasReturnDescription` would fail C-2 by producing `noRtype`; V1 satisfies it.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They were
not run here.

```sh
kompile fvk/mini-autodoc-fieldlist.k --backend haskell
kast --backend haskell fvk/autodoc-typehints-spec.k
kprove fvk/autodoc-typehints-spec.k
```

Expected machine-check result after any syntax adjustments required by the local
K version: `#Top`.

## Test Recommendation

No tests were modified. If tests are editable later, add a public regression case
for documented mode with `:returns:`. Do not remove tests based on this proof
unless the K commands above are run successfully.
