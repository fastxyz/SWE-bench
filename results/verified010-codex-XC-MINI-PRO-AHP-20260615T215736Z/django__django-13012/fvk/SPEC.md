# FVK Specification: django__django-13012

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Target

Production unit under audit:

- `repo/django/db/models/expressions.py`
- `ExpressionWrapper.get_group_by_cols(alias=None)`

Observable behavior under audit:

- The list of expressions Django contributes to SQL `GROUP BY`.
- Whether an expression method receives the `alias` keyword.
- Whether a legacy `get_group_by_cols(self)` override is handled through the
  existing Django 3.2 deprecation path instead of failing with `TypeError`.

The mini-K model abstracts away SQL rendering, database backends, and full
Python object dispatch, but keeps the property that distinguishes the bug:
whether a wrapped expression contributes the wrapper itself or the wrapped
expression's own grouping columns.

## Intent-Only Contract

1. An `ExpressionWrapper` supplies context such as `output_field`; it should not
   replace the wrapped expression's grouping semantics.
2. A constant `Value(...)` contributes no group-by columns. Wrapping it in
   `ExpressionWrapper` must still contribute no group-by columns.
3. For alias-aware expressions, `ExpressionWrapper.get_group_by_cols(alias=A)`
   must forward `A` to the wrapped expression so alias-sensitive grouping, such
   as `Subquery.get_group_by_cols(alias=...)`, remains expressible.
4. Django 3.2 publicly supports custom expressions whose
   `get_group_by_cols()` override lacks `alias=None` only through a deprecation
   warning. Wrapping such an expression must not convert that supported
   transitional path into a raw `TypeError`.
5. The method signature of `ExpressionWrapper.get_group_by_cols()` remains
   `alias=None`; no test files are modified.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
|---|---|---|---|---|
| E-001 | `benchmark/PROBLEM.md` | "Constant expressions of an ExpressionWrapper object are incorrectly placed at the GROUP BY clause" | Wrapped constants must not add themselves to `GROUP BY`. | Encoded by PO-001 and K claim `WRAPPED-VALUE-NO-GROUP-BY`. |
| E-002 | `benchmark/PROBLEM.md` | The unwrapped `Value(3)` query groups only by `"model"."column_a"` | `Value.get_group_by_cols()` semantics must be preserved under wrapping. | Encoded by PO-001. |
| E-003 | `benchmark/PROBLEM.md` | The wrapper is used for "an arbitrary Query expression" | The fix must be transparent for more than `Value`; it must delegate to the child expression. | Encoded by PO-002. |
| E-004 | `benchmark/PROBLEM.md` public hint | "Deferring grouping column resolution to the wrapped expression makes more sense" | `ExpressionWrapper` grouping is child grouping. | Encoded by PO-001 and PO-002. |
| E-005 | `repo/django/db/models/sql/query.py` | Query checks `inspect.signature(annotation.get_group_by_cols)` and warns if `alias` is missing before calling without the keyword. | `alias=None` is a public transition point; missing-alias overrides are deprecated but still handled. | Encoded by PO-004. |
| E-006 | `repo/tests/expressions/test_deprecation.py` | `MissingAliasFunc.get_group_by_cols(self)` is expected to raise `RemovedInDjango40Warning` with a specific message. | The compatibility behavior is warning plus no-arg call, not `TypeError`. | Encoded by PO-004. |
| E-007 | `repo/django/db/models/expressions.py` | `Value.get_group_by_cols(self, alias=None): return []` | Constants contribute no group-by columns. | Encoded by PO-001. |
| E-008 | `repo/django/db/models/expressions.py` | `Subquery.get_group_by_cols()` returns `[Ref(alias, self)]` when `alias` is provided. | Alias-aware wrapped expressions need alias forwarding. | Encoded by PO-002. |

## Formal Core

The formal core is in:

- `fvk/mini-django-expressions.k`
- `fvk/expression-wrapper-spec.k`

The key claims are:

- `WRAPPED-VALUE-NO-GROUP-BY`: `Wrapper(Value(V))` produces `Ok(NoCols)` for
  any alias.
- `WRAPPER-DELEGATES-ALIAS-AWARE`: a wrapper around an alias-aware child
  produces the same columns as the child for the same alias.
- `WRAPPER-PRESERVES-LEGACY-DEPRECATION`: a wrapper around a legacy child whose
  method lacks `alias` produces `Warn(Name, Cols)` and no `TypeError`.

## Adequacy Summary

The K claims match the public intent: they prove the reported constant case, the
general transparent-delegation rule, and the transitional compatibility rule
discovered during the FVK audit. They do not claim to prove full SQL generation,
database execution, or every expression class in Django; those are outside the
observable needed for this issue.
