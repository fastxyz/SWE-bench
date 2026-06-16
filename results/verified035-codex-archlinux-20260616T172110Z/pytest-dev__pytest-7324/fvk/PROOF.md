# FVK Proof

Status: constructed, not machine-checked. No tests, Python code, `kompile`,
`kast`, or `kprove` were run.

## Theorem

For every match-expression input in the audited grammar:

1. Empty input evaluates to `False`.
2. Every accepted non-operator identifier evaluates through the supplied matcher.
3. The specific identifiers `None`, `True`, and `False` do not compile as
   `ast.Name("None")`, `ast.Name("True")`, or `ast.Name("False")`.
4. Boolean composition with `not`, `and`, `or`, and parentheses is preserved.

## Proof Sketch

Case 1: empty expression.

`expression` accepts EOF immediately and returns `ast.NameConstant(False)`.
`ast.fix_missing_locations(ast.Expression(ret))` does not change the represented
value. Evaluation of the compiled expression returns `False` without looking up
any matcher key. This discharges `PO-002`.

Case 2: ordinary identifier `s` where `s` is not `None`, `True`, or `False`.

`not_expr` accepts an `IDENT` token and calls `ident_expr(s)`. The reserved check
fails, so `ident_expr` returns `ast.Name(s, ast.Load())`, matching pre-V2
behavior. During evaluation, Python's name lookup asks `MatcherAdapter` for `s`;
because `s != "@pytest_matcher"`, `MatcherAdapter.__getitem__` returns
`matcher(s)`. This discharges `PO-003` and preserves public matcher semantics.

Case 3: reserved-looking identifier `s` in `{ "None", "True", "False" }`.

`not_expr` again accepts an `IDENT` token and calls `ident_expr(s)`. The reserved
check succeeds, so `ident_expr` returns:

```py
ast.Call(ast.Name("@pytest_matcher", ast.Load()), [ast.Str(s)], [])
```

That AST contains no `ast.Name(s, ...)`. Its only name is the synthetic
`@pytest_matcher`, which the scanner cannot produce from user input because `@`
is an invalid identifier character. Therefore the CPython debug-build assertion
against `Name("None")`, `Name("True")`, and `Name("False")` is not reachable from
these inputs. This discharges `PO-004` and `PO-005`.

At evaluation time, lookup of `@pytest_matcher` reaches
`MatcherAdapter.__getitem__`, which returns the original matcher function. The
call then passes the original string argument `s`, so the result is
`matcher(s)`. Thus `Expression.compile("False").evaluate(lambda _: True)` is
expected to return `True`, while still avoiding `Name("False")`. This discharges
`PO-006` and fixes the V1 regression in `F-002`.

Case 4: boolean composition.

The grammar and parser branches for `not`, `and`, `or`, and parentheses are
unchanged. V2 changes only the AST leaf emitted for the three reserved-looking
identifiers. Python's boolean operators still evaluate the same leaf truth
values with the same short-circuit structure, so expressions such as
`not False`, `True and x`, and `None or x` compose matcher results rather than
constants for those spellings. This discharges `PO-007`.

Case 5: public compatibility.

`Expression.compile` and `Expression.evaluate` keep the same signatures. The
synthetic matcher name and `ident_expr` helper are internal to
`mark/expression.py`; no public tests or public APIs are edited. This discharges
`PO-008`.

## Why V1 Did Not Prove The Right Contract

V1 proved compiler safety by converting the reserved spellings to AST constants.
That proof was adequate for the narrow crash symptom but failed the full public
intent: public tests and docs require `True`, `False`, and `None` to remain valid
matcher identifiers. V2 proves the stronger contract: no debug-build abort and
no identifier-to-constant semantic regression.

## Machine Check Commands

The following commands are the intended later machine-check path after
materializing the obligations into K files. They were not executed here.

```sh
kompile fvk/mini-pytest-expression.k --backend haskell
kast --backend haskell fvk/pytest-expression-spec.k
kprove fvk/pytest-expression-spec.k
```

Expected result: `#Top`.

## Test Guidance

No tests were modified. Because this proof is constructed and not
machine-checked, no existing tests should be removed. Public tests covering
identifier matcher semantics, especially `True`, `False`, and `None`, should be
kept. A focused additional test, if test edits were allowed, would assert that
`Expression.compile("False")` compiles on Python 3.8+ debug builds and evaluates
through the matcher.
