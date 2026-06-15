# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Preserve `simple_col` through nested `Q` recursion

Intent links: SPEC I-002, I-003, I-005.

Formal claim: C-001 in `fvk/SPEC.md` and the first claim in
`fvk/django-query-spec.k`.

Obligation: in `_add_q(q_object, ..., simple_col=S)`, every descendant lookup
leaf must be passed to `build_filter(..., simple_col=S)`.

Discharge: V1 changes the recursive `Node` branch from omitting `simple_col` to
passing it through:

`self._add_q(child, used_aliases, branch_negated, current_negated, allow_joins,
split_subq, simple_col)`.

Direct lookup children already passed `simple_col` to `build_filter()`, so the
base case and recursive case now agree.

## PO-002: Reported mixed `OR`/`AND` check constraint uses bare columns

Intent links: SPEC I-001, I-002, I-003.

Formal claim: C-003 in `fvk/SPEC.md` and the third claim in
`fvk/django-query-spec.k`.

Obligation: for `node(node(leaf, leaf), leaf)` with `simple_col=True`, all three
leaves compile to `simpleLeaf`.

Discharge: follows from PO-001 with `S=True`. The nested left child no longer
falls back to `False`.

## PO-003: Ordinary query filters retain table-qualified `Col` behavior

Intent link: SPEC I-006.

Formal claim: C-002 in `fvk/SPEC.md` and the second claim in
`fvk/django-query-spec.k`.

Obligation: for `_add_q(..., simple_col=False)`, every descendant lookup leaf
continues to compile as regular `Col`.

Discharge: V1 propagates the existing value of `simple_col`; it does not force
the flag to `True`. `Query.add_q()` still calls `_add_q()` through the default
`simple_col=False`.

## PO-004: Expression-valued lookup sides inherit the same mode

Intent links: SPEC I-002, I-003, I-005.

Obligation: an `F()` expression or other resolvable lookup value inside a nested
`Q` reached from `build_where()` must receive `simple_col=True` as well.

Discharge: `build_filter()` calls
`resolve_lookup_value(value, can_reuse, allow_joins, simple_col)`. Once PO-001
preserves `simple_col` into nested `build_filter()` calls, expression-valued
lookup sides inherit the schema-predicate mode.

## PO-005: Public compatibility and API frame

Intent link: SPEC I-006.

Obligation: the fix must not change public method signatures, caller contracts,
connector/negation handling, join promotion, or backend SQL templates.

Discharge: V1 changes only an internal recursive call argument. The callee
already had the `simple_col` parameter, and no public callsite is changed.

## PO-006: Backend-independent localization

Intent links: SPEC I-001, I-004, I-005.

Obligation: the fix should address SQLite and Oracle by changing the shared
query-construction path, not by backend-specific alias stripping.

Discharge: V1 changes `Query._add_q()`, upstream of backend-specific schema SQL
templates and quoting. Both reported backends consume the resulting expression
tree after the `Col` versus `SimpleCol` choice is already made.
