# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` commands were run.

## Claims Proved in the Model

The proof refers to `fvk/mini-django-case.k` and `fvk/django-case-spec.k`.

1. `caseOneAsSql(Full, "True", .Params, "False", .Params)` rewrites to
   `render("CASE WHEN 1=1 THEN True ELSE False END", .Params)`.

2. `whenAsSql(Pred("id = %s", params("7")), "True", params("then"))`
   rewrites to `render("WHEN id = %s THEN True", params("7") +Params params("then"))`.

3. `caseOneAsSql(Empty, "selected", .Params, "not selected", .Params)`
   rewrites to `render("not selected", .Params)`.

## Proof Sketch

For the full-predicate claim, `Full` models the `WhereNode.as_sql()` result
`("", [])`, which the source comment defines as a node that matches everything.
The V1 branch in `When.as_sql()` corresponds to the K rule:

`whenAsSql(Full, RESULT, RPARAMS) => render("WHEN 1=1 THEN " + RESULT, RPARAMS)`

Composing that branch with the one-case `Case` rendering rule yields:

`CASE WHEN 1=1 THEN True ELSE False END`

The predicate `1=1` is true in every row context, so searched `CASE` semantics
select the `then` branch. This proves the reported issue's intended result in
the modeled compiler fragment.

For non-empty predicates, the K rule requires `CONDITION =/=String ""` and
renders the original template with condition parameters followed by result
parameters. Since V1 only changes the `condition_sql == ""` path, ordinary
predicate rendering is preserved.

For impossible predicates, the K model uses `Empty` to represent the
`EmptyResultSet` path. V1 does not catch `EmptyResultSet` in `When.as_sql()`;
therefore `Case.as_sql()` keeps its previous behavior of skipping the case.
The one-case abstraction then reaches the default SQL.

## Adequacy Check

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and
`fvk/SPEC_AUDIT.md` compares them to `fvk/INTENT_SPEC.md`. All required
behaviors pass the adequacy gate. The proof does not certify the full Django
ORM, database execution, termination, or performance.

## Machine-Check Commands

These commands are recorded for a future environment with K installed. They
were not executed in this session.

```sh
kompile fvk/mini-django-case.k --backend haskell
kast --backend haskell fvk/django-case-spec.k
kprove fvk/django-case-spec.k
```

Expected machine-check result: `kprove` discharges the claims to `#Top`.

## Test Guidance

Do not remove tests based on this constructed proof alone. A focused test for
`Case(When(~Q(pk__in=[]), then=Value(True)), default=Value(False))` would be
subsumed by the full-predicate claim only after machine-checking and ordinary
Django test execution are available. Integration tests for database-specific SQL
execution should be kept because the K fragment models only the expression
compiler path.
