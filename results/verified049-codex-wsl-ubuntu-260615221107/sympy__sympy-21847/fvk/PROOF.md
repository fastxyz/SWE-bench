# Constructed Proof

Status: constructed, not machine-checked. No K tooling, tests, or Python were run.

## Claims Proved

The constructed proof covers the integer total-degree path of `itermonomials`:

1. For any generated candidate represented by nonnegative exponent counts `CS`, the V2 filter accepts exactly when `totalDegree(CS) >= min_degree`.
2. The mixed-monomial counterexample `[1, 2, 0]`, `min_degree = 3` is accepted by V2 and rejected by the legacy maximum-exponent predicate.
3. The early unit-monomial branch yields `1` exactly when its total degree `0` satisfies the lower bound, i.e. `min_degree == 0`.
4. The list-valued degree mode and public API shape are unchanged.

## Proof Sketch

Let `CS` be the exponent-count list computed from a candidate item by counting every factor unequal to `1`.

By definition, `totalDegree(CS) = sum(CS)`. The documented integer-mode postcondition requires `min_degree <= totalDegree(monom) <= max_degree`. Candidate construction already bounds total degree above by `max_degree` because every item has exactly `max_degree` slots and slots occupied by `1` contribute zero degree. Therefore the only remaining candidate-level check is the lower bound `sum(CS) >= min_degree`.

V2 uses `sum(powers.values()) >= min_degree` in both the commutative and non-commutative branches. Since `powers.values()` are exactly the exponent counts for non-`1` factors in the candidate item, V2's branch predicate is equivalent to the required lower-bound predicate.

The pre-fix predicate `max(powers.values()) >= min_degree` is not equivalent. For `CS = [1, 2, 0]` and `min_degree = 3`, the legacy predicate checks `2 >= 3` and rejects the candidate; the total-degree predicate checks `3 >= 3` and accepts it. This is the issue's reported mixed-monomial class.

For the unit branch, `S.One` has total degree `0`. Thus yielding `S.One` is correct exactly when `min_degree == 0`. V1 yielded it for `variables == []` even when `min_degree > 0` and `max_degree >= min_degree`; V2 adds the needed `min_degree == 0` guard.

## Adequacy

The adequacy gate passes: `FORMAL_SPEC_ENGLISH.md` claims C1-C7 are entailed by `INTENT_SPEC.md` obligations I1-I9. The proof does not depend on candidate-derived order or legacy behavior. It also does not claim full end-to-end SymPy machine verification; F4 records that limitation.

## Commands to Machine-Check Later

These commands are emitted for a future environment with K installed. They were not run here.

```sh
cd fvk
kompile mini-monomials.k --backend haskell
kast --backend haskell itermonomials-spec.k
kprove itermonomials-spec.k
```

Expected machine-check result after any syntax adjustments required by the local K version: `#Top` for the stated mini-model claims.

## Test Recommendations

Do not delete tests from this task. If the K proof is later machine-checked and the project tests are expanded, point tests for integer total-degree filtering would be subsumed by the proof within the modeled domain. Integration tests, generator behavior tests, and SymPy expression canonicalization tests should remain because the mini-model abstracts those concerns.
