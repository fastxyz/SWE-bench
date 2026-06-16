# FVK Proof Obligations

Status: constructed, not machine-checked. The K-style claims below are the
formal core for this audit, written as obligations to be materialized into
`mini-pytest-expression.k` and `pytest-expression-spec.k` before running K.

Exact commands to run later, not executed in this session:

```sh
kompile fvk/mini-pytest-expression.k --backend haskell
kast --backend haskell fvk/pytest-expression-spec.k
kprove fvk/pytest-expression-spec.k
```

Expected machine-check result after materialization: `#Top`.

## Model Vocabulary

Reserved identifiers:

```k
syntax Bool ::= isReserved(String)
rule isReserved("None") => true
rule isReserved("True") => true
rule isReserved("False") => true
rule isReserved(_) => false [owise]
```

AST fragment:

```k
syntax AExp ::= ConstFalse
              | Name(String)
              | Str(String)
              | MatcherCall(String)
              | Not(AExp)
              | And(AExp, AExp)
              | Or(AExp, AExp)
```

Evaluation environment:

```k
syntax Value ::= Bool | Matcher
syntax Bool ::= applyMatcher(Matcher, String)
syntax Value ::= lookup(MatcherAdapter, String)
```

The synthetic matcher name is `@pytest_matcher`. The scanner grammar does not
accept `@`, so user input cannot collide with it.

## Obligations

`PO-001` Lexical operator partition.

Claim: scanner output classifies exact lowercase `and`, `or`, and `not` as
operators, and any other accepted identifier spelling as `IDENT`.

Why: preserves the existing expression grammar and prevents the fix from
changing boolean syntax.

K-style claim:

```k
claim <k> lexIdent(S) => IDENT(S) </k>
  requires S =/=K "and" andBool S =/=K "or" andBool S =/=K "not"
```

`PO-002` Empty expression is false.

Claim: if `expression` sees EOF immediately, it returns `ConstFalse`; evaluation
does not call the matcher.

Why: public semantics explicitly state empty expressions evaluate false.

K-style claim:

```k
claim <k> expression(EOF) => ConstFalse </k>
claim <k> eval(ConstFalse, ADAPTER) => false </k>
```

`PO-003` Ordinary identifiers preserve legacy matcher lookup.

Claim: for every identifier `S` not in the reserved set, `ident_expr(S)` returns
`Name(S)`, and evaluation under `MatcherAdapter(M)` returns `applyMatcher(M,S)`.

Why: preserves existing behavior for ordinary idents and the public tests for
punctuation-containing idents such as `123.232` and `a+-b`.

K-style claim:

```k
claim <k> identExpr(S) => Name(S) </k>
  requires isReserved(S) ==K false

claim <k> eval(Name(S), adapter(M)) => applyMatcher(M, S) </k>
  requires S =/=K "@pytest_matcher"
```

`PO-004` Reserved identifiers use matcher-call AST, not constant AST.

Claim: for every `S` in `{ "None", "True", "False" }`, `ident_expr(S)` returns
`MatcherCall(S)`.

Why: this is the core V2 correction. It avoids `Name(S)` while preserving
identifier-as-matcher semantics.

K-style claim:

```k
claim <k> identExpr(S) => MatcherCall(S) </k>
  requires isReserved(S) ==K true
```

`PO-005` Reserved identifiers are compiler-safe.

Claim: `MatcherCall(S)` contains no `Name(S)` subterm for reserved `S`; its only
`Name` is `Name("@pytest_matcher")`.

Why: CPython's debug assertion is over name-op compilation for `None`, `True`,
and `False`. The internal name is outside the scanner's identifier language and
not one of those strings.

K-style claim:

```k
claim <k> astNames(MatcherCall(S)) => ListItem("@pytest_matcher") </k>
  requires isReserved(S) ==K true
```

`PO-006` Reserved identifiers still evaluate through the matcher.

Claim: evaluating `MatcherCall(S)` under `MatcherAdapter(M)` returns
`applyMatcher(M,S)`.

Why: discharges `F-002`; `Expression.compile("False").evaluate(lambda _: True)`
must return `True`, not the Python constant `False`.

K-style claim:

```k
claim <k> lookup(adapter(M), "@pytest_matcher") => M </k>

claim <k> eval(MatcherCall(S), adapter(M)) => applyMatcher(M, S) </k>
  requires isReserved(S) ==K true
```

`PO-007` Boolean composition is unchanged.

Claim: replacing a reserved leaf `Name(S)` with `MatcherCall(S)` does not alter
the parser tree shape for `not`, `and`, `or`, or parentheses; those operators
continue to compose leaf truth values using Python boolean semantics.

Why: fixes the leaf construction only.

K-style claim:

```k
claim <k> eval(Not(E), A) => notBool eval(E, A) </k>
claim <k> eval(And(E1, E2), A) => eval(E2, A) </k>
  requires eval(E1, A) ==K true
claim <k> eval(And(E1, E2), A) => false </k>
  requires eval(E1, A) ==K false
claim <k> eval(Or(E1, E2), A) => true </k>
  requires eval(E1, A) ==K true
claim <k> eval(Or(E1, E2), A) => eval(E2, A) </k>
  requires eval(E1, A) ==K false
```

`PO-008` Public compatibility frame.

Claim: V2 changes no public method signatures and modifies no tests. The only
new symbol is an internal module constant plus an internal AST helper.

Why: public callers of `Expression.compile(input)` and
`Expression.evaluate(matcher)` remain compatible.

K-style frame condition:

```k
claim publicAPI(V2) => publicAPI(V1)
```
