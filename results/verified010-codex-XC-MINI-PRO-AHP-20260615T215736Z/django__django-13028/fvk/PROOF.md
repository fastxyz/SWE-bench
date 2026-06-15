# FVK Proof

Status: constructed, not machine-checked. The following commands are recorded
for later human execution only and were not run:

```sh
cd fvk
kompile mini-django-query.k --backend haskell
kast --backend haskell query-filterable-spec.k
kprove query-filterable-spec.k
```

## Unit Under Proof

`Query.check_filterable(expression)` is modeled as `checkFilterable(OBJ)` over
abstract objects:

`obj(HAS_RESOLVE, FILTERABLE, HAS_SOURCES, SOURCES)`

`HAS_RESOLVE` stands for `hasattr(expression, 'resolve_expression')`.
`FILTERABLE` stands for `getattr(expression, 'filterable', True)`.
`HAS_SOURCES` stands for `hasattr(expression, 'get_source_expressions')`.
`SOURCES` is the list returned by `get_source_expressions()` for real
expressions.

## Claim: NON-EXPRESSION-RHS

Precondition: `HAS_RESOLVE == false`.

Postcondition: result is `ok`.

Proof sketch: V2 executes the first branch:

```python
if not hasattr(expression, 'resolve_expression'):
    return
```

This branch returns before the `filterable` guard and before the source
expression walk. Therefore `filterable=False` on ordinary RHS data cannot
produce `NotSupportedError`. This discharges PO-01 and the reported failure in
F-01. It also discharges the V1 audit finding F-02 because a non-expression
object with an unrelated `get_source_expressions` method is not inspected.

## Claim: NON-FILTERABLE-EXPRESSION

Precondition: `HAS_RESOLVE == true` and `FILTERABLE == false`.

Postcondition: result is `notSupported`.

Proof sketch: the early return does not apply. The next branch evaluates
`not getattr(expression, 'filterable', True)` to true and raises
`NotSupportedError`. This preserves Django's internal expression contract and
discharges PO-02 and F-03.

## Claim: FILTERABLE-EXPRESSION-NO-SOURCES

Precondition: `HAS_RESOLVE == true`, `FILTERABLE == true`, and
`HAS_SOURCES == false`.

Postcondition: result is `ok`.

Proof sketch: the early return does not apply, the `filterable` rejection branch
does not apply, and the source-expression loop is skipped. The function returns
normally. This covers the filterable-expression base case for PO-03.

## Claim: FILTERABLE-EXPRESSION-SOURCES

Precondition: `HAS_RESOLVE == true`, `FILTERABLE == true`, and
`HAS_SOURCES == true`.

Postcondition: the result is equivalent to validating each element of
`SOURCES` using `check_filterable()` in order, returning `notSupported` if any
source is rejected and `ok` if all sources are accepted.

Proof sketch: after passing the parent expression's own filterability guard,
V2 executes the unchanged loop:

```python
for expr in expression.get_source_expressions():
    self.check_filterable(expr)
```

The circularity is the recursive call to the same contract on the tail of the
source list. The empty-list case returns normally. The non-empty case takes one
real recursive validation step on the head before applying the same claim to the
remaining list. If a source is non-filterable by PO-02, the raised
`NotSupportedError` propagates. Otherwise validation proceeds to the next
source. This discharges PO-03 and F-04.

## Composition With `build_filter()`

For the reported call, `build_filter()` resolves the RHS with
`resolve_lookup_value()`. A model instance without `resolve_expression` remains
a direct value. `build_filter()` then calls `check_filterable(value)`, which
returns by `NON-EXPRESSION-RHS`, and execution proceeds to
`check_related_objects()`. This discharges PO-04.

## Residual Risk

This is a partial correctness proof over a small abstract model. It does not
prove SQL generation, database behavior, or total correctness of the whole query
compiler. It also was not machine-checked because the benchmark forbids running
K tooling. The proof is adequate for the issue's expression-protocol boundary
because the model preserves the exact observable that distinguished the bug:
whether a value is treated as expression metadata or ordinary RHS data.

## Test Recommendation

Do not remove any tests based on this run. After machine-checking, in-domain
unit tests that assert ordinary RHS values with `filterable=False` do not raise
the expression `NotSupportedError` would be subsumed by PO-01. Integration tests
for actual queryset SQL and relation validation should be kept because they are
outside this unit proof.
