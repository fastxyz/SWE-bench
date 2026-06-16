# FVK Spec: `Query.resolve_lookup_value()`

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were run.

## Scope

The audited unit is `repo/django/db/models/sql/query.py`,
`Query.resolve_lookup_value()`, with the downstream `__range` lookup behavior
used only as public intent and compatibility evidence. The formal model is a
small value-domain model that distinguishes:

- scalar lookup values;
- expression-like values whose `resolve_expression()` result is abstracted as a
  value;
- lists;
- plain tuples;
- named tuples.

The model intentionally does not formalize the whole Django query compiler or
database execution path. That is outside this issue and outside the fragment
needed to distinguish the reported failing and passing cases.

## Public Intent Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| IE1 | `benchmark/PROBLEM.md` | "named 2-tuples as arguments to range queryset filters" | A two-field named tuple is in domain for `__range` lookup values. | Encoded in `CLAIM-NAMED-TWO-TUPLE-RANGE`. |
| IE2 | `benchmark/PROBLEM.md` | "works fine on 2.2" and "causes ... TypeError" | The intended behavior is successful lookup-value resolution, not the constructor error. | Encoded as no-error postcondition for named tuples. |
| IE3 | `benchmark/PROBLEM.md` | "goes into the tuple elements to resolve lookups" | Each element of a list/tuple/named tuple must be recursively resolved. | Encoded in all container claims. |
| IE4 | `benchmark/PROBLEM.md` | "attempts to reconstitute the tuple ... preserves the type" | Reconstruction should keep the original container kind. | Encoded for lists, plain tuples, and named tuples. |
| IE5 | `benchmark/PROBLEM.md` | "The fix is to * expand the contents of the iterator into the constructor." | Named tuple reconstruction must call the constructor with positional resolved elements, not one iterable argument. | Encoded in `CLAIM-NAMED-TWO-TUPLE-RANGE`. |
| IE6 | `repo/django/db/models/lookups.py` | `FieldGetDbPrepValueIterableMixin.get_prep_lookup()` iterates `self.rhs`; `Range.get_rhs_op()` uses two RHS SQL entries. | The range RHS must remain an iterable with two ordered values after resolution. | Compatibility obligation PO5. |
| IE7 | `repo/django/db/models/sql/query.py` | Existing non-named list/tuple branch reconstructed with `type(value)(iterable)`. | Plain list/tuple behavior should not be changed as part of this targeted bug fix. | Frame obligation PO4. |

## Intent-Only Contract

For in-domain finite lookup values:

1. If the value has `resolve_expression`, `resolve_lookup_value()` returns that
   expression's resolved value.
2. If the value is a list, tuple, or named tuple, each element is recursively
   resolved with the same `can_reuse` and `allow_joins` arguments and in the
   same iteration order.
3. A standard named tuple used as a two-element `__range` value is reconstructed
   as the same named tuple type using positional resolved elements. It must not
   be passed a single generator/iterator argument.
4. Plain lists and plain tuples retain the pre-existing iterable-constructor
   reconstruction behavior.
5. Non-expression scalar values are returned unchanged.
6. The method signature and caller/callee protocol are unchanged.

Preconditions:

- Container inputs are finite.
- A named tuple is a standard Python named tuple shape: it is a tuple instance
  with `_fields`, and its constructor accepts one positional argument per field.
- Behavior inside arbitrary `resolve_expression()` implementations is external
  to this unit and modeled as an abstract resolved value.

## Formal Artifacts

- `fvk/mini-python.k` contains the mini value-domain semantics.
- `fvk/resolve-lookup-value-spec.k` contains K-style claims for expression,
  scalar, list, plain tuple, and named tuple cases.
- `fvk/FORMAL_SPEC_ENGLISH.md` paraphrases those claims.
- `fvk/SPEC_AUDIT.md` checks the paraphrases against this intent contract.

## Adequacy Result

The formal model preserves the property that matters for this issue: named tuple
inputs are distinguishable from plain tuple inputs, and reconstruction shape is
observable in the result. A model that collapsed named tuples to plain tuples
would be inadequate because it could not distinguish the bug from the fix.
