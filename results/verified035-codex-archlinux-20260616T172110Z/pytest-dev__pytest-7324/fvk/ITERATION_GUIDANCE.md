# FVK Iteration Guidance

Status: V2 source change recommended and applied.

## Source Guidance

Keep the V2 implementation in `repo/src/_pytest/mark/expression.py`.

The key decision is to avoid `ast.Name("None"|"True"|"False")` without changing
those spellings into constants. The reserved spellings now compile to an
explicit matcher call, and `MatcherAdapter` exposes the internal matcher binding.
This resolves `F-001` and `F-002` while satisfying `PO-004`, `PO-005`, and
`PO-006`.

Do not restore the V1 helper in `compat.py`. The corrected behavior depends on
`MatcherAdapter`, so it belongs in `mark/expression.py`; see `F-003` and
`PO-008`.

Keep the empty-expression path as a real false constant. It is not a parsed
identifier and must not call `matcher("False")`; see `PO-002`.

## Future Test Guidance

Do not delete tests based on this constructed proof. Machine-checking has not
run.

If tests could be edited in a future task, add coverage for:

- `Expression.compile("False")` on a Python 3.8+ debug build does not abort.
- `Expression.compile("False").evaluate(lambda ident: ident == "False")` is
  `True`.
- `Expression.compile("True").evaluate(lambda ident: ident == "True")` is
  `True`.
- `Expression.compile("None").evaluate(lambda ident: ident == "None")` is
  `True`.
- `Expression.compile("").evaluate(lambda ident: True)` remains `False`.

Existing public tests for `test_valid_idents` and `-k "None"` should be kept
until a machine-checked proof exists and even then may remain useful integration
coverage.

## Machine-Check Guidance

Materialize the K-style claims from `PROOF_OBLIGATIONS.md` into:

- `fvk/mini-pytest-expression.k`
- `fvk/pytest-expression-spec.k`

Then run, outside this no-execution environment:

```sh
kompile fvk/mini-pytest-expression.k --backend haskell
kast --backend haskell fvk/pytest-expression-spec.k
kprove fvk/pytest-expression-spec.k
```

Expected result: `#Top`.

## Residual Watch Item

V2 special-cases only the three names in CPython's reported debug assertion. If
future CPython versions reject additional arbitrary AST name strings, the next
iteration should consider routing every parsed identifier through the explicit
matcher-call representation. That broader change is not required by the current
public issue and would need its own compatibility audit.
