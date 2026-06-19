# FVK Notes

## Decision Summary

V1 did not fully stand. The FVK audit found one incompleteness: V1 preserved
direct column references and raw SQL, but it could drop a subquery grouping
expression whose dependency on outer columns is represented through
`Query.get_external_cols()` rather than `contains_column_references`.

I changed `repo/django/db/models/sql/compiler.py` so the order-by grouping
filter now also keeps expressions whose flattened sources expose non-empty
external columns. This addresses `fvk/FINDINGS.md` F1 and discharges
`fvk/PROOF_OBLIGATIONS.md` PO4.

## Decisions Traced To FVK Artifacts

Kept V1's exclusion of `Random()` from order-by grouping. This is justified by
`fvk/FINDINGS.md` F2 and `fvk/PROOF_OBLIGATIONS.md` PO1: random ordering has no
column dependency and must not alter aggregate grouping.

Kept V1's direct-column preservation. This is justified by
`fvk/PROOF_OBLIGATIONS.md` PO2 and the public issue's `order_by('related')`
example, which expects column-dependent ordering to remain grouping-relevant.

Kept V1's raw SQL exception. This is justified by `fvk/PROOF_OBLIGATIONS.md`
PO3 and the public hint that raw SQL must still be included because it cannot
be introspected reliably.

Added the external-column preservation branch. This is justified by
`fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO4. The source evidence is
`Subquery.get_group_by_cols()`, which can return the subquery itself when
external columns are possibly multivalued; V1's predicate would have treated
that expression as column-free.

Kept reference orderings skipped. This is justified by
`fvk/PROOF_OBLIGATIONS.md` PO5 and the existing compiler comment that selected
references are already grouped through the select path.

Left select grouping, HAVING grouping, `collapse_group_by()`, SQL rendering,
method signatures, and return shapes unchanged. This is justified by
`fvk/PROOF_OBLIGATIONS.md` PO7 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.

## Verification Status

The FVK proof is constructed, not machine-checked. Per the task constraints, I
did not run tests, Python, `kompile`, `kast`, or `kprove`. The exact commands to
run later are recorded in `fvk/SPEC.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.
