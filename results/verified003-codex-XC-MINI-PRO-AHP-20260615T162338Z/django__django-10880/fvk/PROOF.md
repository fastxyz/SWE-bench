# Constructed Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`, `kast`, or `kprove` were run.

## Summary

The V1 source change satisfies the public intent: distinct aggregate SQL now renders `DISTINCT ` with a trailing separator before the rendered aggregate expression. Because Django's aggregate templates concatenate `%(distinct)s%(expressions)s`, this is the point where the separator must be supplied.

## Proof Sketch

For PO-1, inspect `Aggregate.as_sql()`: when `self.distinct` is true, `extra_context['distinct']` is `DISTINCT `. The K semantics mirrors this with `distinctMarker(true) => "DISTINCT "`.

For PO-2, `Func.as_sql()` computes `data['expressions']` from compiled source expressions and interpolates `Aggregate.template`, whose relevant shape is `%(function)s(%(distinct)s%(expressions)s)`. Substituting `function="COUNT"`, `distinct="DISTINCT "`, and `expressions="CASE WHEN P THEN X ELSE NULL END"` yields `COUNT(DISTINCT CASE WHEN P THEN X ELSE NULL END)`. This is K claim C-1.

For PO-3, the false distinct branch still supplies the empty string. Substituting `distinct=""` yields `COUNT(CASE WHEN P THEN X ELSE NULL END)`, so V1 does not introduce a non-distinct formatting change. This is K claim C-2.

For PO-4, the backend fallback branch in `Aggregate.as_sql()` copies the aggregate, clears `copy.filter`, wraps the first source expression in `Case(When(self.filter, then=source_expressions[0]))`, and then calls `super(Aggregate, copy).as_sql(..., **extra_context)`. Since `extra_context['distinct']` was set before the branch, the fallback path uses the same `DISTINCT ` marker. This is K claim C-3.

For PO-5, the native filter branch wraps the aggregate template with `filter_template`, so the base aggregate first renders `COUNT(DISTINCT X)`, then appends `FILTER (WHERE P)`. This is K claim C-4.

For PO-6, the diff changes only the literal true-branch marker string. No method signature, constructor, return shape, or parameter behavior changes. Non-distinct rendering is separately covered by PO-3.

## Machine-Check Commands

These are intentionally not executed in this task.

```sh
cd fvk
kompile mini-django-aggregate.k --backend haskell
kast --backend haskell aggregate-spec.k
kprove aggregate-spec.k
```

Expected machine-check result after installing K and running the commands: `#Top` for all claims.

## Test Recommendations

Do not delete tests in this task.

Conditionally redundant after machine-checking: a focused unit test that asserts `Count(Case(...), distinct=True)` renders SQL containing `COUNT(DISTINCT CASE` rather than `COUNT(DISTINCTCASE` would be subsumed by C-1.

Keep: integration tests that execute generated SQL on actual database backends; compatibility tests for aggregate filters; tests for unsupported aggregate/distinct combinations such as SQLite multi-argument distinct aggregates. The proof models token construction only, not database execution behavior.

## Residual Risk

The proof is constructed, not machine-checked. The trusted base is the adequacy of the mini string semantics to the reported token-adjacency bug, the source inspection that maps Django's code to that semantics, and the future K toolchain result.

No source issue was found that justifies changing V1.
