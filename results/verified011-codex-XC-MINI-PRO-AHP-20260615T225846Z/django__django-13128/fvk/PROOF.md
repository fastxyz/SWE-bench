# Proof

Status: constructed, not machine-checked.

## Summary

The V1 fix is correct for the public intent: same-type temporal subtraction now
resolves to `DurationField` during output-field inference, so the reported
expression composes as `DurationField + DurationField`. Non-special arithmetic
continues through the existing generic resolver, and SQL rendering remains
unchanged.

## Machine-Check Commands Not Run

Do not run these in this benchmark session. They are recorded for a future K
environment:

```sh
(cd fvk && kompile mini-django-expressions.k --backend haskell)
(cd fvk && kast --backend haskell temporal-subtraction-spec.k)
(cd fvk && kprove temporal-subtraction-spec.k)
```

Expected machine-check result after running in a valid K environment:
`kprove` returns `#Top` for all claims.

## Constructed Proof

P1. Same-type temporal subtraction

For `DateField`, `DateTimeField`, and `TimeField`, the K function
`sameTemporalSub(SUB, T, T)` rewrites to `true`. Therefore
`resolveOutput(SUB, T, T)` takes the first resolver rule and rewrites to
`DurationField`. This discharges PO1 and claims `DATE-SUB`, `DATETIME-SUB`,
and `TIME-SUB`.

P2. Reported nested expression

Start with:

```text
resolveOutput(ADD, resolveOutput(SUB, DateTimeField, DateTimeField), DurationField)
```

By P1, the inner subtraction rewrites to `DurationField`. The outer expression
is therefore:

```text
resolveOutput(ADD, DurationField, DurationField)
```

`sameTemporalSub(ADD, DurationField, DurationField)` is false, so the resolver
delegates to `genericOutput(DurationField, DurationField)`, which rewrites to
`DurationField`. This discharges PO2 and claim
`ISSUE-NESTED-DATETIME-DURATION`.

P3. Generic fallback preservation

For `resolveOutput(ADD, DateTimeField, DurationField)`,
`sameTemporalSub(...)` is false, so generic inference receives two distinct
known types and rewrites to `FieldError`. For
`resolveOutput(ADD, IntegerField, IntegerField)`, generic inference receives
matching known types and rewrites to `IntegerField`. This discharges PO4.

P4. SQL alignment

The K model mirrors the existing SQL branch predicate:
`sqlKind(SUB, DateTimeField, DateTimeField)` rewrites to
`TemporalSubtractionSQL`, and `sqlOutput(TemporalSubtractionSQL)` rewrites to
`DurationField`. Source inspection confirms V1 did not edit
`CombinedExpression.as_sql()` or `TemporalSubtraction.as_sql()`. This discharges
PO3.

P5. Compatibility

Source inspection shows no public signatures or test files changed after V1.
`CombinedExpression.as_sql()` and `resolve_expression()` retain their call
shapes. This discharges PO5.

## Adequacy Gate

The English paraphrases in `fvk/FORMAL_SPEC_ENGLISH.md` match the public intent
in `fvk/INTENT_SPEC.md`; `fvk/SPEC_AUDIT.md` marks every claim as pass. The
formal claims do not preserve the reported mixed-type error.

## Test Redundancy Recommendation

No tests should be deleted in this benchmark. If the K claims are later
machine-checked, focused tests that assert the same finite type-resolution
facts could be considered redundant, but integration tests that exercise actual
query compilation, backend SQL generation, and result conversion should be
kept.

## Residual Risk

This proof is partial and constructed. It does not prove termination properties,
though the modeled resolver is a finite rewrite system with no loops. It also
does not replace Django backend integration tests because the model abstracts
SQL text and database behavior away from the audited type-resolution property.
