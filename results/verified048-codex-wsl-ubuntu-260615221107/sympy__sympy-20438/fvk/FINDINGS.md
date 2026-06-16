# FVK Findings

Status: constructed, not machine-checked.

## F1: Missing ProductSet-to-FiniteSet subset rule

Input: `ProductSet(FiniteSet(1, 2), FiniteSet(1, 2)).is_subset(FiniteSet((1, 1), (1, 2), (2, 1), (2, 2)))`

Observed in pre-fix public issue: the call returned no truth value (`None`).

Expected from public intent E1-E3: `True`, because every element of the finite
Cartesian product is present in the explicit finite set.

Classification: code bug, resolved by the `ProductSet, FiniteSet` subset
handler in `repo/sympy/sets/handlers/issubset.py`.

Proof obligations: PO1, PO3.

## F2: V1 could raise while enumerating a known-finite but symbolic product

Input family: a `ProductSet` whose `is_finite_set` is `True`, but whose
iterator can still raise `TypeError` or `ValueError` due to undecidable
membership or symbolic range cardinality. A representative source-derived case
is a product containing an `Intersection` with a finite candidate and
undecidable membership, or a symbolic `Range` whose finite status is known but
whose size validation cannot enumerate concrete elements.

Observed in V1 by source audit: the V1 handler directly iterated
`for x in a_product` under `if a_product.is_finite_set`, so iterator exceptions
would escape the subset query.

Expected from intent E6 and existing fuzzy-set behavior: the result should be
`None` when the subset relation cannot be safely decided.

Classification: code bug surfaced by FVK audit, resolved in V2 by catching
`TypeError` and `ValueError` around finite-product enumeration and returning
`None`.

Proof obligation: PO4.

## F3: Equality needed the same subset fact to avoid the issue traceback

Input: `Eq(ProductSet(FiniteSet(1, 2), FiniteSet(1, 2)), FiniteSet((1, 1), (1, 2), (2, 1), (2, 2))).simplify()`

Observed in public issue: generic relational simplification reached
`Complement` and raised `AttributeError` because the set difference object had
no `.equals` method.

Expected from intent E4-E5: equivalent finite product and explicit finite set
should compare equal by mutual subsethood, avoiding that generic difference
path.

Classification: code bug adjacent to the subset bug, resolved by
`ProductSet`/`FiniteSet` equality dispatch in
`repo/sympy/sets/handlers/comparison.py`.

Proof obligation: PO5.

## F4: Formal proof is constructed, not machine-checked

Input: the FVK `.k` artifacts in this directory.

Observed in this session: no `kompile`, `kast`, `kprove`, Python, or tests were
run, per task constraints.

Expected: a later environment with K installed should execute the commands
listed in `fvk/PROOF.md` and expect all claims to discharge to `#Top`.

Classification: proof-status caveat, not a code bug. Test removal is not
recommended until machine-checking is performed.

