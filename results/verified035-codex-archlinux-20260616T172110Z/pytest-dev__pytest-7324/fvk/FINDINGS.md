# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source, public in-repo tests/docs, and symbolic reasoning only.

## `F-001` Original compiler-abort bug

Classification: code bug, fixed by V2.

Evidence: the issue shows `Expression.compile("False")` aborting a Python 3.8+
debug build in `compiler_nameop`, whose assertion rejects AST names equal to
`None`, `True`, or `False`.

Input -> observed vs expected:

`Expression.compile("False")` on pre-fix code -> observed interpreter abort from
an `ast.Name("False", ast.Load())`; expected normal compilation of a match
expression.

Reasoning: pre-fix `not_expr` emitted `ast.Name(ident.value, ast.Load())` for
every identifier. For `False`, that directly constructs the AST shape CPython's
debug compiler rejects.

Resolution: V2 routes those three spellings through `MatcherCall(s)`, so the AST
no longer contains `Name("False")`, `Name("True")`, or `Name("None")` for user
identifiers. See `PO-004` and `PO-005`.

## `F-002` V1 semantic regression for reserved-looking identifiers

Classification: code bug in V1, fixed by V2.

Evidence: public matcher intent says identifiers are evaluated through a matcher.
Public tests list `"True"` and `"False"` as valid identifiers, and
`testing/test_mark.py` expects `-k "None"` to match a parametrized node whose id
contains `None`. Historical docs also state `-k None` filters tests with `None`
in their name.

Input -> observed vs expected:

`Expression.compile("False").evaluate(lambda ident: True)` under V1 -> observed
`False`, because V1 compiled `False` as a Python constant; expected `True`,
because `"False"` is a valid match-expression identifier and the matcher returns
`True` for it.

`-k "None"` under V1 -> observed no match by constant semantics; expected
matching node ids containing `"None"`.

Reasoning: V1 satisfied `F-001` by changing `True`, `False`, and `None` into AST
constants. That avoids the compiler assertion but contradicts the documented and
tested matcher-identifier contract.

Resolution: V2 keeps `True`, `False`, and `None` as matcher-backed identifiers by
emitting an explicit matcher call for only those three spellings. See `PO-004`
and `PO-006`.

## `F-003` Helper placement from V1 was too broad

Classification: design/compatibility finding, fixed by V2.

Evidence: V1 placed `_ident_to_name` in `compat.py` and made it return constants
for reserved spellings. The corrected behavior depends on the private
`MatcherAdapter` evaluation context in `mark/expression.py`.

Input -> observed vs expected:

Internal helper used outside marker expressions -> observed risk of exporting a
mark-expression-specific AST convention as general Python compatibility;
expected the special AST rewrite to live next to the evaluator that supplies the
synthetic matcher binding.

Resolution: V2 removes the `compat.py` helper and keeps `ident_expr` local to
`mark/expression.py`. See `PO-008`.

## `F-004` No open source-code finding after V2

Classification: confirmation, constructed not machine-checked.

Evidence: V2 covers the original crash family, preserves public matcher
semantics for reserved-looking identifiers, leaves the empty expression false,
and does not change public method signatures.

Input -> observed vs expected:

`Expression.compile("False").evaluate(matcher)` under V2 -> expected
`matcher("False")` without constructing `Name("False")`.

`Expression.compile("")` under V2 -> expected `False` without consulting the
matcher.

Residual risk: this conclusion is not machine-checked and no tests were run.
Machine checking would require materializing the K claims and running the
commands listed in `PROOF_OBLIGATIONS.md`.
