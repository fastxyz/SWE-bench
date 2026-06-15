# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent item | Result | Notes |
|---|---|---|---|
| OUTERREF-SHIFT | I1, I2 | pass | The claim says the user `OuterRef('pk')` survives the generated `split_exclude()` subquery and binds to the enclosing query level. |
| PLAIN-F-PRESERVED | I3 | pass | The claim preserves the pre-existing `F()` compensation: local `F()` values bind to the immediate parent query. |
| NON-EXPRESSION-PRESERVED | I4 | pass | The claim states non-expression RHS values are not scope-shifted. |
| V0-COUNTEREXAMPLE | I1, public hint E3 | pass as a bug witness | The claim intentionally models the old behavior and reaches the wrong immediate-parent binding. It is evidence for the fix, not a desired postcondition. |
| Compatibility audit | I5 | pass | No public signature or return-shape change was made. |

## Adequacy Result

The formal claims cover the observable issue property: which query level receives the `OuterRef('pk')` binding after `split_exclude()` introduces a generated nested subquery. They do not claim to verify full SQL generation, join trimming, null handling, or database execution.

