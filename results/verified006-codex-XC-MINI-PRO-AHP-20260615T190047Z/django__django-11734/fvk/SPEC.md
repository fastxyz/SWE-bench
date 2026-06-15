# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were run.

## Scope

This FVK pass audits the V1 fix for `django__django-11734`: the scope transformation in `Query.split_exclude()` when a negated many-valued relation lookup contains `OuterRef()`.

The full Django ORM is outside this mini semantics. The modeled observable is deliberately narrow but property-complete for the reported bug: after Django creates the internal split-exclude subquery, which query level does the reference bind to?

## Public Intent Ledger

The full ledger is in `PUBLIC_EVIDENCE_LEDGER.md`. The critical obligations are:

- E1/E2: `OuterRef()` in `exclude()` and `~Q()` must use the intended outer model.
- E3: the bad behavior is binding to the immediate `Item` alias instead of the enclosing `Number` alias.
- E4: nested `OuterRef` is the existing Django mechanism for delaying resolution by one query level.
- E5: plain `F()` references already have a deliberate one-level shift and must remain compatible.
- E7: no public API or call signature should change.

## Abstract Model

The mini K model represents references as:

- `FRef(name)`: a plain local `F(name)`.
- `OuterRef(ref)`: an outer reference wrapper.
- `Resolved(name)`: Django's `ResolvedOuterRef(name)`, still waiting to bind when the containing query is resolved as a subquery.
- `Bound(level, name)`: a concrete column binding to an abstract query level.
- `Literal(value)`: a non-expression RHS value.

The relevant query levels are:

- `0`: the generated `split_exclude()` query.
- `1`: the immediate parent query, such as the `Item` query inside `Exists()`.
- `2`: the enclosing query, such as the public `Number` query.

The lifecycle is modeled as `pipeline(ref, 0, 1, 2)`:

1. `splitShift(ref)`: apply `split_exclude()`'s RHS rewrite.
2. `resolveStep(..., 0)`: resolve while adding the filter to the generated query.
3. `resolveStep(..., 1)`: resolve while attaching the generated query to the immediate parent query.
4. `resolveStep(..., 2)`: resolve the parent query as a subquery of the enclosing query.

## Formal Claims

The claims are in `outerref-split-exclude-spec.k`.

- `OUTERREF-SHIFT`: `pipeline(OuterRef(FRef("pk")), 0, 1, 2) => Bound(2, "pk")`.
- `PLAIN-F-PRESERVED`: `pipeline(FRef("local_field"), 0, 1, 2) => Bound(1, "local_field")`.
- `NON-EXPRESSION-PRESERVED`: `pipeline(Literal("rhs"), 0, 1, 2) => Literal("rhs")`.
- `V0-COUNTEREXAMPLE`: `pipelineV0(OuterRef(FRef("pk")), 0, 1, 2) => Bound(1, "pk")`.

## Adequacy

The adequacy audit in `SPEC_AUDIT.md` marks the claims as aligned with the intent. The V0 counterexample is intentionally a failing legacy path, not a desired behavior.

