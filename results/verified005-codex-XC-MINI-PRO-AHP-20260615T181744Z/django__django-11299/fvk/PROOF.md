# Constructed Proof

Status: constructed, not machine-checked. The task forbids running tests,
Python, `kompile`, `kast`, or `kprove`.

## Commands to machine-check later

From the workspace root:

```sh
kompile fvk/mini-django-query.k --backend haskell
kast --backend haskell fvk/django-query-spec.k
kprove fvk/django-query-spec.k
```

Expected result after the toolchain is available: `kprove` discharges the claims
to `#Top`.

## Proof summary

The modeled observable is the column-rendering mode assigned to each lookup leaf
while recursively compiling a finite `Q` tree. `simpleLeaf` corresponds to
`SimpleCol`; `colLeaf` corresponds to regular table-qualified `Col`.

For a leaf lookup, Django already passed `simple_col` from `build_filter()` to
`_get_col()`. Therefore the base case holds:

- if `simple_col=True`, the leaf compiles to `SimpleCol`;
- if `simple_col=False`, the leaf compiles to `Col`.

For a nested `Q` node, correctness requires both recursive children to be
compiled with the same incoming flag. Before V1, the recursive call omitted the
flag, so Python's default `simple_col=False` applied to nested children. This is
the counterexample in F-001: the nested `AND` side of an `OR` used `Col`.

V1 passes `simple_col` to the recursive `_add_q()` call. By structural induction
on the finite `Q` tree:

- Base: a leaf receives the root flag in `build_filter()` and compiles to the
  corresponding column mode.
- Step: a node with left and right subtrees passes the same flag to both
  recursive calls; by the induction hypothesis both subtrees compile with the
  required mode at every leaf.

Thus PO-001 holds for every finite nested `Q` tree in the `build_where()` domain.
PO-002 is the concrete reported tree
`node(node(leaf, leaf), leaf)` with `simple_col=True`; all three leaves compile
to `simpleLeaf`, matching the expected bare-column check constraint.

PO-003 follows from the same induction with `simple_col=False`. Since
`Query.add_q()` still enters `_add_q()` through the default `False` value, V1
does not change ordinary query filters.

PO-004 follows because nested leaves now call `build_filter()` with the correct
flag, and `build_filter()` already passes that flag to `resolve_lookup_value()`
for `F()` and other resolvable lookup values.

PO-005 and PO-006 are frame obligations. V1 does not change any method
signature, connector handling, join promotion, backend schema templates, or SQL
quoting. It only preserves an existing parameter across recursion in the shared
query-construction path.

## Adequacy and residual risk

The proof is adequate for the reported defect because the model keeps the exact
axis the issue observes: whether a nested schema-predicate leaf is compiled as
`SimpleCol` or `Col`. A passing instance and failing instance remain
distinguishable in the model:

- failing pre-V1 instance: `node(node(leaf, leaf), leaf)` with root `true`
  produces nested `colLeaf` values;
- passing V1 instance: the same tree produces only `simpleLeaf` values.

Residual risk is limited to the normal FVK MVP caveat: this proof is constructed
but not machine-checked. No test removal is recommended until the commands above
are actually run and return `#Top`.

## Test guidance

Do not delete tests based on this proof alone. Useful public tests, if editing
tests were allowed, would assert generated SQL for a mixed `OR`/`AND`
`CheckConstraint` contains bare column names throughout and no
`"new__table"."column"` references in the constraint expression.
