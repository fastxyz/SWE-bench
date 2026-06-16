# FVK Findings

Status: findings from `/formalize` and `/verify` methodology. Proof is constructed, not machine-checked.

## F1: Legacy Integer Filter Used Largest Single Exponent

Classification: code bug, resolved by V1 and retained in V2.

Evidence: `benchmark/PROBLEM.md` says integer mode should return all monomials satisfying `min_degree <= total_degree(monom) <= max_degree`, and explicitly names mixed monomials such as `x1*x2**2`.

Concrete input: variables `[x1, x2, x3]`, `max_degree = 3`, `min_degree = 3`, candidate exponent counts `[1, 2, 0]`.

Observed before V1: the predicate `max(powers.values()) >= min_degree` evaluates as `2 >= 3`, so the mixed monomial is rejected.

Expected: `sum(powers.values()) >= min_degree` evaluates as `3 >= 3`, so the mixed monomial is accepted.

Resolution: V2 keeps V1's `sum(powers.values()) >= min_degree` predicate in both commutative and non-commutative branches.

Related proof obligations: PO-4, PO-5, PO-6.

## F2: V1 Still Yielded `1` for Empty Variables with Positive `min_degree`

Classification: code bug surfaced by FVK, resolved in V2.

Evidence: the docstring/public issue total-degree contract says integer mode yields monomials with `min_degree <= total_degree(monom) <= max_degree`. Public tests establish that the empty variable case has the unit monomial `1`; its total degree is `0`.

Concrete input: `variables = []`, `max_degree = 2`, `min_degree = 1`.

Observed in V1: after `min_degree > max_degree` failed, the `if not variables or max_degree == 0` branch yielded `S.One`.

Expected: no monomial, because `total_degree(1) = 0`, which does not satisfy `1 <= total_degree(1)`.

Resolution: V2 changes the early unit-monomial branch to yield `S.One` only when `min_degree == 0`.

Related proof obligations: PO-2.

## F3: Public Test Gap for Integer `min_degrees`

Classification: test gap; no test files modified per task instruction.

Evidence: public tests cover default integer mode and list-valued `min_degrees`, but do not cover nontrivial integer `min_degrees` on mixed monomials or empty variables with `max_degree >= min_degree > 0`.

Recommended tests after code review, not applied here:

- `set(itermonomials([x, y, z], 3, 3))` includes `x*y**2` and other total-degree-3 mixed monomials.
- `set(itermonomials([x, y, z], 4, 3))` includes total-degree-3 and total-degree-4 monomials.
- `set(itermonomials([], 2, 1)) == set()`.
- A non-commutative integer-min case includes mixed words of total degree at least `min_degree`.

Related proof obligations: PO-4, PO-5, PO-2.

## F4: Mini-K Model Abstracts SymPy Expression Canonicalization

Classification: proof capability gap / trusted abstraction boundary, not a code bug.

The constructed K model proves the total-degree filter over exponent-count candidates. It does not model the full Python generator protocol, `itertools`, `Mul` canonicalization, or SymPy's commutative/non-commutative expression equality. This is acceptable for the audited defect because the discriminator is the candidate's total non-identity factor count, which the model preserves.

Machine-checking and a fuller Python/SymPy semantics would be needed before claiming end-to-end machine verification or removing tests.

Related proof obligations: PO-3, PO-4, PO-5.

## F5: No Public Compatibility Blocker

Classification: compatibility confirmation.

The public signature and generator return shape are unchanged. Non-test source callsites found in the repo pass no `min_degrees`, so they remain on the default lower-bound `0` path.

Related proof obligations: PO-8.
