# Formal Spec In English

Status: constructed, not machine-checked.

## `DMP-EXT-FACTOR-SPEC` claims

1. Issue claim: for the abstract polynomial representing
   `(x - 1)*(y - 1)` with `YMINUS1` as main-variable content and `XMINUS1` as
   the primitive factor, V1 returns both factors with coefficient `1`.
2. Legacy diagnostic claim: the pre-V1 candidate path returns only `XMINUS1`
   for the same abstract polynomial. This is intentionally a diagnostic of the
   bug, not an expected behavior.
3. No-content frame claim: if the content factor bag is empty and the content
   coefficient is `1`, V1 behaves like the original primitive/norm path and
   returns the primitive factors with the original leading coefficient.
4. Content-only claim: if the primitive factor bag is empty, V1 returns the
   content factors and multiplies the original leading coefficient by the
   recursively factored content coefficient.
5. Coefficient claim: for a concrete coefficient example, `LC = 3` and
   `CC = 5` produce returned coefficient `15`, while preserving factor
   multiplicities.
6. General claim: for every well-formed primitive/content split,
   `dmpExtFactor(poly(LC, CC, CONT, PRIM))` returns coefficient `LC * CC` and
   the union of `CONT` and `PRIM`, preserving multiplicity.

## `DMP-EXT-FACTOR-OBLIGATIONS` claims

1. `BAG-COVERAGE`: content candidates plus primitive candidates cover every
   factor in the original factor bag. This requires structural induction over
   factor bags.
2. `TRIAL-MULTIPLICITY`: trial division preserves original multiplicities when
   the candidate list contains each irreducible factor key. Full discharge
   depends on SymPy dense division soundness.
3. `PRIMITIVE-SPLIT`: `dmp_primitive`'s content/primitive split reconstructs
   the monic input. Full discharge depends on multivariate GCD soundness.
4. `NORM-CANDIDATES`: the existing square-free norm path is complete for the
   primitive part over algebraic fields. V1 keeps this obligation unchanged.

## Frame conditions

- No public API signature or return shape changes.
- Factor ordering is intentionally not specified.
- The univariate `dup_ext_factor` path is outside the modified code path.
