# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not edit `repo/django/db/models/aggregates.py` further.

The FVK audit found that V1 satisfies the required public intent for `Avg` and
`Sum` and that the existing shared SQL path already propagates the distinct
flag after construction.

## Trace to Findings and Obligations

Keep `Avg.allow_distinct = True`.

Reason: F-001 is resolved by PO-1. Removing or changing this line would
reintroduce the reported exception for `Avg(..., distinct=True)`.

Keep `Sum.allow_distinct = True`.

Reason: F-002 is resolved by PO-2. Removing or changing this line would
reintroduce the reported exception for `Sum(..., distinct=True)`.

Do not modify `Aggregate.as_sql()`.

Reason: F-003 and PO-3 show the required SQL behavior already exists once the
constructors accept the distinct flag.

Do not add `allow_distinct = True` to `Min` or `Max` in this pass.

Reason: F-004 and PO-5 classify that text as an optional extension. The public
issue requires `Avg` and `Sum`; widening `Min` and `Max` is not necessary to
discharge the spec.

Do not remove or edit tests.

Reason: F-005 and PO-6. This proof is constructed, not machine-checked, and the
benchmark forbids modifying test files.

## Next Action If Revisiting

If a future public requirement explicitly asks for `Min(..., distinct=True)` or
`Max(..., distinct=True)`, add `allow_distinct = True` to those classes and
extend PO-4/PO-5 accordingly.

If a future environment permits execution, run the commands recorded in
`fvk/PROOF.md` and then the relevant Django aggregate tests.
