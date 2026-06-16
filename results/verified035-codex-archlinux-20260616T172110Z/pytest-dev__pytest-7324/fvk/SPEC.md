# FVK Specification: pytest marker expression reserved identifiers

Status: constructed, not machine-checked. No tests, Python code, or K tooling
were executed.

## Scope

The audited unit is `repo/src/_pytest/mark/expression.py`, specifically the AST
construction and evaluation path used by `Expression.compile(...).evaluate(...)`
for `-k` and `-m` expressions.

There are no loops in this unit. The proof is a partial-correctness argument over
the expression parser/evaluator: if parsing and compilation return normally, the
compiled expression must evaluate according to the public matcher semantics.

## Public Intent Ledger

`I-001` Source: issue prompt.

Quoted evidence: `Expression.compile("False")` aborts a Python 3.8+ debug build
in `compiler_nameop` because an AST `Name` uses `"False"`.

Obligation: compiling a match expression containing `False` must not abort the
interpreter. The generated AST must avoid `ast.Name` nodes whose identifier is
one of `None`, `True`, or `False` on paths that reach CPython compilation.

Status: encoded by `PO-003`, `PO-004`, and discharged by V2.

`I-002` Source: source docstring in `mark/expression.py`.

Quoted evidence: `Empty expression evaluates to False.`

Obligation: empty or whitespace-only input evaluates false without consulting
the matcher.

Status: encoded by `PO-002`; V2 preserves the original `ast.NameConstant(False)`
path.

`I-003` Source: source docstring and option help.

Quoted evidence: `ident evaluates to True of False according to a provided
matcher function`; `all names are substring-matched against test names`.

Obligation: parsed identifiers are matcher lookups, not Python constants, except
for the parser-reserved boolean operators `and`, `or`, and `not`.

Status: encoded by `PO-003`, `PO-004`, `PO-005`, and `PO-006`.

`I-004` Source: public in-repo tests and docs.

Quoted evidence:
`testing/test_mark_expression.py` lists `"True"` and `"False"` under
`test_valid_idents`; `testing/test_mark.py` expects `-k "None"` to select
`test_func[None]`; release notes say `"-k None" filters all tests that have
"None" in their name`.

Obligation: the spellings `True`, `False`, and `None` remain valid matcher
identifiers for match expressions. Fixing the debug-build crash must not turn
them into Python constants.

Status: V1 violated this obligation. V2 encodes it by routing those exact
spellings through an explicit matcher call; see `F-002`, `PO-004`, and `PO-006`.

`I-005` Source: grammar and existing parser tests.

Quoted evidence: `or`, `and`, and `not` are tokenized as boolean operators; other
valid identifier strings include punctuation such as `.`, `+`, `-`, and `[]`.

Obligation: boolean operator parsing and ordinary identifier handling remain
unchanged.

Status: encoded by `PO-001`, `PO-003`, and `PO-007`.

`I-006` Source: public API compatibility audit.

Quoted evidence: public users call `Expression.compile(input)` and
`Expression.evaluate(matcher)`; `MatcherAdapter` and AST helpers are internal.

Obligation: do not change public method signatures, return conventions for
ordinary matcher-backed expressions, or test-file contents.

Status: encoded by `PO-008`.

## Formal Model

The mini-model abstracts Python AST nodes to the observable properties relevant
to the issue:

- `ConstFalse` is a Python AST constant false node.
- `Name(s)` is an AST name lookup that CPython compiles through
  `compiler_nameop`.
- `MatcherCall(s)` is the AST shape
  `Call(Name("@pytest_matcher"), [Str(s)])`.
- `MatcherAdapter.__getitem__("@pytest_matcher")` returns the matcher function.
- `MatcherAdapter.__getitem__(s)` for all other names returns `matcher(s)`.

The reserved set is exactly `{ "None", "True", "False" }`, matching the
debug-build assertion shown in the issue.

## Formal Claims In English

`C-001` Lexing: `and`, `or`, and `not` are operator tokens; all other accepted
identifier strings, including `True`, `False`, and `None`, are `IDENT` tokens.

`C-002` Empty expression: EOF before any expression produces `ConstFalse`.

`C-003` Ordinary identifier: for any identifier `s` not in the reserved set,
`not_expr` produces `Name(s)`, preserving the original matcher lookup behavior.

`C-004` Reserved identifier: for `s` in `{ "None", "True", "False" }`,
`not_expr` produces `MatcherCall(s)`, not `Name(s)`.

`C-005` Compiler safety: `MatcherCall(s)` contains no AST `Name` whose identifier
is `s`; its only name is the internal unscannable `@pytest_matcher`. Therefore
the CPython debug assertion for `None`/`True`/`False` is not reached for those
user identifiers.

`C-006` Matcher preservation: evaluating `MatcherCall(s)` under
`MatcherAdapter(matcher)` returns `matcher(s)`.

`C-007` Boolean composition: `not`, `and`, `or`, and parentheses compose the leaf
results exactly as before; the V2 change only replaces the leaf AST for the
three reserved spellings.

`C-008` Compatibility: `Expression.compile`, `Expression.evaluate`, parse errors,
and public test files are unchanged at the interface level.

## Adequacy Audit

The claims cover the whole public intent for this issue: the original crash
input (`False`), the full debug-assertion family (`None`, `True`, `False`), the
empty-expression boundary, ordinary identifiers, boolean composition, and public
API compatibility.

V1 failed the adequacy gate because it proved compiler safety by changing
`True`, `False`, and `None` into constants, contradicting `I-003` and `I-004`.
V2 is adequate because compiler safety and matcher semantics are both claimed.
