# FVK Notes

I revised V1 instead of confirming it unchanged.

## Decisions

`D-001` Changed the reserved-identifier strategy.

V1 converted `True`, `False`, and `None` to AST constants. `F-002` shows this
violated public matcher semantics, and `PO-004`/`PO-006` require those spellings
to avoid reserved `ast.Name` nodes while still evaluating as `matcher(name)`.
V2 now emits an explicit matcher call for those three identifiers.

`D-002` Kept ordinary identifiers on the original `ast.Name` path.

`PO-003` requires non-reserved identifiers to preserve legacy matcher lookup
behavior. V2 only changes the three names that trigger the CPython debug-build
assertion family from `F-001`.

`D-003` Added the internal matcher binding in `MatcherAdapter`.

The reserved-identifier AST uses `ast.Name("@pytest_matcher", ast.Load())` as a
synthetic function lookup. `PO-006` requires that lookup to produce the original
matcher function, so `MatcherAdapter.__getitem__` now returns `self.matcher` for
that internal key and keeps returning `matcher(key)` for user identifiers.

`D-004` Reverted the V1 `compat.py` helper.

`F-003` shows the helper was too broad once the correct fix depended on
`MatcherAdapter`. `PO-008` frames the public compatibility requirement, so V2
keeps the special AST convention local to `mark/expression.py` and leaves
`compat.py` unchanged from the base commit.

`D-005` Kept the empty-expression false constant.

`PO-002` requires empty input to evaluate false without consulting the matcher.
V2 therefore leaves the empty-expression branch as `ast.NameConstant(False)`
rather than routing it through the reserved-identifier helper.

`D-006` Did not modify tests or run commands.

The task forbids modifying tests and says there is no execution environment.
`F-004` and the proof are therefore labeled constructed, not machine-checked.
The command lines in `PROOF_OBLIGATIONS.md` and `PROOF.md` are recorded for a
future environment but were not executed.

## Result

The V2 source diff is limited to `repo/src/_pytest/mark/expression.py`. It fixes
the debug-build crash mechanism from `F-001`, repairs the V1 regression from
`F-002`, and satisfies the compatibility frame in `PO-008`.
