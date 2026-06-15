# FVK Notes

## Summary

V2 keeps the V1 source fix unchanged. The FVK audit confirms that the required
public behavior is to support `distinct=True` for `Avg` and `Sum`, and the V1
class-attribute changes discharge that requirement through Django's existing
aggregate initialization and SQL rendering paths.

## Decisions

Kept `Avg.allow_distinct = True`.

Trace: `fvk/FINDINGS.md` F-001 identifies the original `Avg(...,
distinct=True)` exception as the reported bug. `fvk/PROOF_OBLIGATIONS.md` PO-1
shows that setting `allow_distinct = True` disables the only distinct-specific
`TypeError` branch for `Avg` and preserves `self.distinct = True`.

Kept `Sum.allow_distinct = True`.

Trace: `fvk/FINDINGS.md` F-002 identifies the original `Sum(...,
distinct=True)` exception as the reported bug. `fvk/PROOF_OBLIGATIONS.md` PO-2
shows that setting `allow_distinct = True` disables the only distinct-specific
`TypeError` branch for `Sum` and preserves `self.distinct = True`.

Did not edit `Aggregate.as_sql()`.

Trace: `fvk/FINDINGS.md` F-003 and `fvk/PROOF_OBLIGATIONS.md` PO-3 show that
the shared SQL path already renders `DISTINCT ` from `self.distinct` for both
filter and non-filter aggregate SQL paths. The bug was the constructor gate,
not SQL rendering.

Did not add distinct support to `Min` or `Max`.

Trace: `fvk/FINDINGS.md` F-004 and `fvk/PROOF_OBLIGATIONS.md` PO-5 classify
the `Min`/`Max` sentence in the public issue as optional: it says the setting
"could" be applied and calls it pointless. The mandatory public intent names
`Avg` and `Sum`.

Did not modify tests.

Trace: `fvk/FINDINGS.md` F-005 and `fvk/PROOF_OBLIGATIONS.md` PO-6 record the
benchmark's no-execution/no-test-editing constraints and the FVK honesty gate.
The proof is constructed, not machine-checked, so test removal is not justified.

## Artifact Changes

Created the required FVK markdown artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Also created the formal-core files referenced by the FVK proof:

- `fvk/mini-django-aggregate.k`
- `fvk/django-aggregate-spec.k`

These K artifacts and the commands in `fvk/PROOF.md` were written for a future
machine-checking environment and were not executed here.

## Source Changes

No V2 source edits were made. The only source diff remains the V1 change in
`repo/django/db/models/aggregates.py`, adding `allow_distinct = True` to `Avg`
and `Sum`.
