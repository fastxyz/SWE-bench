# Formal Spec English

Status: paraphrase of the constructed K claims in `fvk/itermonomials-spec.k`.

C1. For any nonnegative exponent-count list `CS` and nonnegative `MIN`, `acceptByTotal(CS, MIN)` evaluates to `true` exactly when `totalDegree(CS) >= MIN`.

C2. For any nonnegative exponent-count list `CS` and nonnegative `MIN`, `acceptByTotal(CS, MIN)` evaluates to `false` exactly when `totalDegree(CS) < MIN`.

C3. The mixed candidate with exponent counts `[1, 2, 0]` has total degree `3`. With `MIN = 3`, the total-degree filter accepts it.

C4. The legacy maximum-exponent filter rejects the same `[1, 2, 0]` candidate for `MIN = 3` because its largest single exponent is `2`. This is the formal counterexample proving that the pre-fix predicate was not adequate.

C5. In the unit-monomial early branch, when there are no variables or `max_degree == 0`, yielding `1` is correct exactly when `min_degree == 0`; for `min_degree > 0`, the correct output is empty.

C6. List-valued degree mode is not changed by the proof target; the proof imposes no new behavior on that branch beyond preserving its existing per-variable contract.

C7. The proof is over set-membership behavior, not generator order.
