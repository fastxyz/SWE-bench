# FVK Spec for django__django-16032

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The verified unit is the query-selection state used by `Exact`,
`In`, and `RelatedIn` when a `Query` appears on the RHS of a lookup. The
observable under audit is whether the RHS subquery is narrowed to exactly the
field required by the lookup, especially when annotations and aliases have
modified internal annotation masks.

The model abstracts away SQL rendering, joins, model rows, and expression
resolution. It keeps the state dimensions that distinguish the reported failure
from the intended behavior:

- `has_select_fields`: whether a values-style explicit selection exists.
- `select`: default columns, pk selection, related target selection, or explicit
  values selection.
- `annotation_select_mask`: no mask, empty mask, or materialized annotation mask.

This abstraction passes the FVK discriminator: a failing pre-fix state
(`annotate(); alias(); inPrep`) remains distinguishable from a passing state
because the model can observe whether `inPrep` produces `pkSelect` or preserves a
multi-column/default selection.

## Public Intent Ledger

E-001

- Source: prompt.
- Evidence: "`__in` doesn't clear selected fields on the RHS when
  `QuerySet.alias()` is used after `annotate()`."
- Obligation: the combination `annotate(...).alias(...)` must not prevent
  `__in` RHS narrowing when the user did not call `values()` or `values_list()`.
- Status: encoded by PO-001 and claim 1 in `fvk/query-in-spec.k`.

E-002

- Source: prompt/public hint.
- Evidence: "`__in` lookup ... automatically limit selected fields to the pk
  when Query is on the right-side and the selected fields are undefined."
- Obligation: an RHS `Query` with undefined selected fields must be converted to
  a one-column primary-key selection.
- Status: encoded by PO-001 and PO-006.

E-003

- Source: prompt/public hint.
- Evidence: "Whether or not the In lookups defaults a Query right-hand-side to
  `.values('pk')` is based of `rhs.has_select_fields`."
- Obligation: `has_select_fields` must mean values-style explicit selection, not
  arbitrary internal annotation or extra-select masks.
- Status: encoded by PO-001 and PO-002.

E-004

- Source: prompt/public hint.
- Evidence: "replace `Query.has_select_fields` by a class attribute that
  defaults to `False` and have `set_values` set it to `True`."
- Obligation: new queries and annotate/alias-only queries have
  `has_select_fields == False`; `Query.set_values()` sets it to `True`.
- Status: implemented in `repo/django/db/models/sql/query.py`; encoded by
  PO-001, PO-002, and PO-004.

E-005

- Source: prompt/public hint.
- Evidence: "RelatedIn also needs adjustments to make sure it goes through
  `Query.set_values` instead of calling `clear_select_clause` and `add_fields`."
- Obligation: relation-specific RHS field selection must be marked as explicit
  before delegating to base `In`, otherwise base `In` may overwrite it with pk.
- Status: implemented in `repo/django/db/models/fields/related_lookups.py`;
  encoded by PO-003.

E-006

- Source: prompt/public hint.
- Evidence: "`Query.clone` must assign `obj.has_select_fields = True` ... This
  should not be necessary as it's a shallow attribute and it already gets carried
  over."
- Obligation: explicit selection survives cloning.
- Status: encoded by PO-004.

E-007

- Source: Django public API shape and implementation call graph.
- Evidence: the V1 patch changes internal state and one internal method call,
  but does not change public method signatures or return types.
- Obligation: no compatibility update is needed for public callers or subclass
  overrides.
- Status: encoded by PO-005.

## Intent Specification

I-001: For any RHS `Query` used by `__in`, if the user has not selected fields
with a values-style operation, lookup preparation narrows the RHS SELECT list to
the primary key.

I-002: `annotate()` and `alias()` may affect the annotation mask, but they do
not by themselves create a values-style explicit selected-field list.

I-003: If the user has selected fields with `values()` or `values_list()`, lookup
preparation preserves that explicit selection and does not overwrite it with pk.

I-004: For related `__in` lookups where the relation target is not the primary
key, lookup preparation selects the relation-specific target field and preserves
that field through the base `In` preparation.

I-005: Cloning a query preserves values-style selected-field state.

I-006: The fix must not change public signatures, queryset return shapes, or
test files.

## Formal Model

The constructed K artifacts are:

- `fvk/mini-django-query.k`: abstract semantics for query-state transitions.
- `fvk/query-in-spec.k`: K reachability claims corresponding to PO-001 through
  PO-004 and PO-006.

Exact commands to machine-check later, not executed here:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/query-in-spec.k
kprove fvk/query-in-spec.k
```

Expected machine-check result if the abstract semantics and claims parse as
written: `#Top` for all claims.

## Formal Spec English and Adequacy Audit

Claim 1 says: after `annotate`, then `alias`, then base `In` preparation, a
query with no values-style selected fields is narrowed to `pkSelect`.

- Adequacy: pass. This is exactly E-001 plus E-002.

Claim 2 says: after `setValues(explicit)`, base `In` preparation preserves
`explicitSelect`.

- Adequacy: pass. This is I-003 and follows from the "selected fields are
  undefined" condition in E-002.

Claim 3 says: a related `__in` lookup with a non-primary-key relation target and
no prior explicit selection ends with `targetSelect`, not `pkSelect`.

- Adequacy: pass. This is E-005.

Claim 4 says: after `setValues(explicit)`, cloning, and base `In` preparation,
the selection remains `explicitSelect`.

- Adequacy: pass. This is E-006.

Claim 5 says: the one-row `Exact` lookup path treats annotate+alias-only RHS
queries as unselected and narrows them to `pkSelect`.

- Adequacy: pass. `Exact` uses the same discriminator as `In`; keeping the
  discriminator semantics consistent is required by E-003.

No formal claim is derived solely from V1 behavior. Each nontrivial claim is
traced to public issue text, public hints, or Django's existing public API shape.

## Public Compatibility Audit

Changed symbol: `Query.has_select_fields`.

- Before V1: private computed property.
- After V1: private query state with class default `False`, set to `True` by
  `set_values()`.
- Public compatibility status: pass. This is an internal ORM query attribute,
  and no public callable signature or result type changes.

Changed call: `RelatedIn.get_prep_lookup()` uses `rhs.set_values([target_field])`
instead of `rhs.add_fields([target_field], True)`.

- Public compatibility status: pass. This preserves the same lookup method
  signature and changes only internal query state preparation.

Tests: no test files were modified. No test deletion is recommended because the
proof is constructed, not machine-checked.
