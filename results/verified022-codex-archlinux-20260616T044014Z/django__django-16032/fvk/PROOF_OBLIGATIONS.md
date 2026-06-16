# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are the checklist
used to decide whether V1 stands or needs a V2 source edit.

## PO-001: Annotate plus alias RHS defaults to pk for `__in`

- Intent entries: E-001, E-002, E-003, E-004.
- Formal claim: `fvk/query-in-spec.k`, claim 1.
- Precondition: RHS query starts without values-style explicit selected fields.
- Program path: `annotate ; aliasAfterAnnotate ; inPrep`.
- Required postcondition: final selection is `pkSelect`.
- Source code under audit:
  - `repo/django/db/models/sql/query.py`: `has_select_fields = False`.
  - `repo/django/db/models/sql/query.py`: `add_annotation()` does not set
    `has_select_fields`.
  - `repo/django/db/models/lookups.py`: `In.get_prep_lookup()` narrows RHS to pk
    when `not self.rhs.has_select_fields`.
- V1 status: discharged. Annotation-mask materialization no longer makes the RHS
  look explicitly selected.

## PO-002: Explicit values-style selection is preserved by base `In`

- Intent entries: E-002, E-003, E-004.
- Formal claim: `fvk/query-in-spec.k`, claim 2.
- Precondition: RHS query reaches `Query.set_values()`.
- Program path: `setValues(explicit) ; inPrep`.
- Required postcondition: final selection is `explicitSelect`, not `pkSelect`.
- Source code under audit:
  - `repo/django/db/models/sql/query.py`: `set_values()` sets
    `self.has_select_fields = True`.
  - `repo/django/db/models/lookups.py`: `In.get_prep_lookup()` leaves RHS
    selection alone when `has_select_fields` is true.
- V1 status: discharged.

## PO-003: Related non-primary-key target survives base `In`

- Intent entries: E-005.
- Formal claim: `fvk/query-in-spec.k`, claim 3.
- Precondition: `RelatedIn` receives an RHS query with no explicit selected
  fields, and the relation target field is not the primary key.
- Program path: `relatedInPrep(false, false)`.
- Required postcondition: final selection is `targetSelect`, not `pkSelect`.
- Source code under audit:
  - `repo/django/db/models/fields/related_lookups.py`:
    `self.rhs.set_values([target_field])`.
  - `repo/django/db/models/lookups.py`: base `In.get_prep_lookup()` observes
    `has_select_fields == True` after `set_values()`.
- V1 status: discharged.

## PO-004: Clone preserves explicit selected-field state

- Intent entries: E-006.
- Formal claim: `fvk/query-in-spec.k`, claim 4.
- Precondition: `Query.set_values()` has written instance state before cloning.
- Program path: `setValues(explicit) ; clone ; inPrep`.
- Required postcondition: final selection remains `explicitSelect`.
- Source code under audit:
  - `repo/django/db/models/sql/query.py`: `clone()` copies `self.__dict__`.
- V1 status: discharged. No explicit clone assignment is necessary because the
  `True` state is an instance attribute.

## PO-005: Public compatibility is preserved

- Intent entries: E-007.
- Formal claim: covered by the compatibility audit in `fvk/SPEC.md`.
- Precondition: public callers use existing `QuerySet`, lookup, and related
  lookup APIs.
- Required postcondition: public signatures, return types, and test files remain
  unchanged.
- Source code under audit:
  - `repo/django/db/models/sql/query.py`: private attribute implementation
    changed, no public signature changed.
  - `repo/django/db/models/fields/related_lookups.py`: internal helper call
    changed, no public signature changed.
- V1 status: discharged.

## PO-006: One-row `Exact` lookup keeps the same discriminator semantics

- Intent entries: E-002, E-003.
- Formal claim: `fvk/query-in-spec.k`, claim 5.
- Precondition: RHS is a `Query` limited to one row with no values-style
  selected fields, including the annotate+alias-only case.
- Program path: `annotate ; aliasAfterAnnotate ; exactPrepOne`.
- Required postcondition: final selection is `pkSelect`.
- Source code under audit:
  - `repo/django/db/models/lookups.py`: `Exact.get_prep_lookup()` uses
    `has_select_fields` the same way as base `In` after checking
    `has_limit_one()`.
- V1 status: discharged.

## PO-007: Do not over-preserve legacy implementation details

- Intent entries: E-001 through E-004.
- Formal claim: adequacy audit in `fvk/SPEC.md`.
- Precondition: a proposed proof condition would rely on the old property's
  implementation-derived behavior, such as `annotation_select_mask` implying
  selected fields.
- Required postcondition: no proof obligation treats legacy annotation-mask
  inference as intended behavior.
- V1 status: discharged. The proof claims are intent-derived and do not rely on
  the pre-fix computed property.

## Summary

All production-code proof obligations are discharged by V1 under the constructed
abstract model. The proof is not machine-checked because this task forbids
running K tooling.
