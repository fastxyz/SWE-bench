# FVK Specification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited unit is the schema-predicate path:

- `CheckConstraint._get_check_sql()` and `UniqueConstraint._get_condition_sql()`
  call `Query.build_where()`.
- `Query.build_where()` calls `_add_q(..., allow_joins=False,
  simple_col=True)`.
- `_add_q()` recursively walks a finite `Q` tree and delegates leaf lookups to
  `build_filter()`.
- `build_filter()` passes `simple_col` to `_get_col()`, which returns
  `SimpleCol` when `simple_col` is true and regular `Col` otherwise.

The concrete issue concerns `CheckConstraint`; conditional unique constraints
share the same schema-predicate builder and are included as frame coverage. The
spec excludes joined-field references because `build_where()` intentionally sets
`allow_joins=False` and existing code raises `FieldError` for joined paths.

## Public Intent Ledger

I-001, source: prompt. Evidence: "CheckConstraint with OR operator generates
incorrect SQL on SQLite and Oracle." Obligation: generated check-constraint SQL
must be valid for schema creation/rebuild on those backends.

I-002, source: prompt. Evidence: the expected SQL is
`CHECK ((("field_1" IS NOT NULL AND "flag" = 1) OR "flag" = 0))`. Obligation:
schema-level check predicate columns must render as bare column names, not
table-qualified names.

I-003, source: prompt. Evidence: "combination of OR and AND clauses" and "AND
clause items using Col while the OR clause uses SimpleCol." Obligation:
nested `Q` nodes must preserve the same bare-column rendering mode as direct
children.

I-004, source: code. Evidence: `SimpleCol` is documented as a column name
without table name "to avoid a syntax error in check constraints." Obligation:
the intended mechanism for schema predicates is `SimpleCol`, not SQL string
post-processing.

I-005, source: code. Evidence: `Query.build_where()` calls `_add_q(...,
allow_joins=False, simple_col=True)`. Obligation: every descendant lookup
compiled through `build_where()` inherits `simple_col=True`.

I-006, source: compatibility. Evidence: ordinary `Query.add_q()` calls
`_add_q()` without `simple_col=True`. Obligation: ordinary query filters keep
regular table-qualified `Col` behavior.

## Intent Spec

For any finite `Q` tree in the `build_where()` domain, every lookup leaf must be
compiled using `SimpleCol` when the root call has `simple_col=True`. This must
hold uniformly through `AND`, `OR`, and nested `Q` nodes.

For ordinary query filtering, where `_add_q()` is entered with the default
`simple_col=False`, lookup leaves must continue to compile using regular `Col`.

The fix must not alter public APIs, method signatures, connector/negation
structure, join-promotion behavior, or backend quoting.

## Formal Model

The formal core reduces the relevant Django behavior to a finite binary `Q`
tree:

- `leaf` represents a lookup passed to `build_filter()`.
- `node(left, right)` represents a nested `Q` node.
- `compile(tree, true)` models `_add_q(..., simple_col=True)`.
- `compile(tree, false)` models `_add_q(..., simple_col=False)`.
- `simpleLeaf` means the lookup leaf reaches `_get_col(..., simple_col=True)`.
- `colLeaf` means the lookup leaf reaches `_get_col(..., simple_col=False)`.

The K-style artifacts are:

- `fvk/mini-django-query.k`
- `fvk/django-query-spec.k`

## Formal Spec English

C-001: For every finite `Q` tree `Q`, `compile(Q, true)` produces the same tree
shape with every lookup leaf marked `simpleLeaf`.

C-002: For every finite `Q` tree `Q`, `compile(Q, false)` produces the same tree
shape with every lookup leaf marked `colLeaf`.

C-003: For the reported shape `(field_1 IS NOT NULL AND flag = true) OR
flag = false`, represented as `node(node(leaf, leaf), leaf)`, compiling with
`simple_col=True` produces `nodeM(nodeM(simpleLeaf, simpleLeaf), simpleLeaf)`.

## Spec Audit

C-001 passes against I-002, I-003, I-004, and I-005. It is exactly the
bare-column schema-predicate obligation.

C-002 passes against I-006. It is the compatibility frame for ordinary query
filters.

C-003 passes against I-001, I-002, and I-003. It is the concrete reported issue
shape.

No claim is derived solely from V1 behavior. V1 is treated as the candidate
implementation checked against the intent above.

## Public Compatibility Audit

No public method signature changed. The edited call is an internal recursive
call to `_add_q()` and passes an existing parameter already present in the
callee signature.

Public callsites found in source remain compatible:

- `Query.add_q()` still calls `_add_q(q_object, self.used_aliases)`, preserving
  `simple_col=False`.
- `Query.build_where()` still calls `_add_q(..., simple_col=True)`.
- `Q.resolve_expression()` calls `_add_q(..., allow_joins=allow_joins,
  split_subq=False)` and therefore preserves the default `simple_col=False`.

No test files were modified.
