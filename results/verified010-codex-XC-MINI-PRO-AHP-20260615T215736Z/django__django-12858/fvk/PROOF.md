# PROOF.md

Status: constructed, not machine-checked.

## What is proved

The constructed proof covers the related-ordering path walker inside `Model._check_ordering()`:

- A final unresolved segment registered as a lookup on the previously resolved field is accepted (`PO-1`).
- A registered transform remains accepted (`PO-2`).
- A lookup-like unresolved segment is not accepted in the middle of a path unless it is also a transform (`PO-3`).

The proof is partial correctness over the path walker abstraction. Termination is immediate for finite path lists because each rule consumes one path outcome.

## Formal Core

The mini semantics in `mini-django-ordering.k` models the changed block as a list-consuming validator:

- `field(F)` records the previous resolved field.
- `missing(N)` triggers the same validity decision as the patched `except` block.
- `hasTransform(F, N)` and `hasLookup(F, N)` model Django's registries.
- Finality is represented structurally by whether the rest of the outcome list is `.Outcomes`.

The claims in `ordering-check-spec.k` are:

- `REPORTED-CASE`: `supply`, `product`, and `parent` resolve, then final `isnull` is missing as a field but registered as a lookup on `parent`; result is `ok`.
- `FINAL-LOOKUP-VALID`: any `missing(L)` with empty rest and `hasLookup(F, L)` true reaches `ok`.
- `TRANSFORM-STILL-VALID`: any `missing(T)` with `hasTransform(F, T)` true reaches `ok`.
- `NONFINAL-LOOKUP-INVALID`: if `missing(L)` is followed by more path, has no transform, and is only a lookup, validation reaches `err`.

## Constructed Proof Sketch

1. `REPORTED-CASE`: symbolic execution consumes `field(F_SUPPLY)`, `field(F_PRODUCT)`, and `field(F_PARENT)`, setting the previous field to `F_PARENT`. The next item is `missing(isnull)` with empty rest. The semantics uses the final-lookup rule because `hasTransform(F_PARENT, isnull) = false` and `hasLookup(F_PARENT, isnull) = true`, so the result is `ok`.
2. `FINAL-LOOKUP-VALID`: the state starts at `#walk(missing(L) ; .Outcomes, some(F))` with the side condition that `L` is a registered lookup and not a transform. The final-lookup rule fires directly and reaches `ok`.
3. `TRANSFORM-STILL-VALID`: the state starts at `#walk(missing(T) ; REST, some(F))` with `hasTransform(F, T) = true`. The transform rule consumes the missing segment and continues with the rest. In the concrete claim the rest is empty, so the validator reaches `ok`.
4. `NONFINAL-LOOKUP-INVALID`: the state starts at `#walk(missing(L) ; NEXT ; REST, some(F))` with no transform and a registered lookup. Because the rest is non-empty, the final-lookup rule is inapplicable; the invalid-missing rule fires and reaches `err`.

## Adequacy Gate

`FORMAL_SPEC_ENGLISH.md` paraphrases each claim. `SPEC_AUDIT.md` marks all claim paraphrases as matching the intent ledger. No claim is derived solely from V1 behavior; the final-lookup obligation traces to the public issue, while transform and invalid-path obligations trace to existing source behavior that the issue did not ask to change.

## Machine-Check Commands

These commands were not executed:

```sh
cd fvk
kompile mini-django-ordering.k --backend haskell
kast --backend haskell ordering-check-spec.k
kprove ordering-check-spec.k
```

Expected later machine-check result: `kprove` returns `#Top`.

## Test Guidance

No test files were modified. Tests that would exercise the proof obligations should be kept until the K claims and Django test suite can be run in an execution-capable environment:

- Add or keep a model check test for `ordering = ('supply__product__parent__isnull',)`.
- Add or keep a model check test for `ordering = ('-supply__product__parent__isnull',)`.
- Keep invalid ordering tests for missing related fields and non-final lookup-like segments.

No test-removal recommendation is made because the proof is constructed, not machine-checked, and the task forbids executing the suite.
