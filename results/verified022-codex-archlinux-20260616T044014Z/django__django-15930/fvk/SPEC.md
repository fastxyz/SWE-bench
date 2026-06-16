# FVK Spec

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited observable is the SQL fragment produced by the Django expression
compiler path:

`WhereNode.as_sql()` -> `When.as_sql()` -> `Case.as_sql()`

The target source method is `When.as_sql()` in
`repo/django/db/models/expressions.py`. The relevant public behavior is a
searched `CASE` expression whose `When` condition is `~Q(pk__in=[])`.

The K fragment abstracts the compiler result of a condition into three cases:

- `Full`: a condition matching everything, represented by `WhereNode.as_sql()`
  as `("", [])`.
- `Empty`: an impossible condition, represented by `EmptyResultSet`.
- `Pred(sql, params)`: an ordinary non-empty predicate.

## Public Intent Ledger

| ID | Evidence | Obligation |
|---|---|---|
| I1 | Problem title: "Case() crashes with ~Q(pk__in=[])." | A `Case` with this condition must compile without SQL syntax error. |
| I2 | Reported bad SQL: `CASE WHEN THEN True ELSE False END`. | The empty `WHEN` predicate is the defect. |
| I3 | Expected behavior: "annotate all rows with the value True since they all match." | `~Q(pk__in=[])` is full/true and must select the `then` value for every row. |
| I4 | Sentinel note: `~Q(pkin=[])` may be returned by application code. | The fix should handle the general full-predicate sentinel path, not only a single concrete model field. |
| I5 | `WhereNode.as_sql()` comment: `Return '', [] if this node matches everything`. | Empty condition SQL from a `WhereNode` is a full predicate. |
| I6 | Existing `Case.as_sql()` behavior catches `EmptyResultSet` and skips a case. | Impossible predicates must remain false/fall-through. |
| I7 | Public test `test_annotate_with_empty_when` expects `When(pk__in=[])` to use the default. | Do not convert impossible empty `IN` to true. |
| I8 | `When.template = "WHEN %(condition)s THEN %(result)s"`. | The condition slot must contain a valid predicate, not an empty string. |

## Specification

O1. If `compiler.compile(self.condition)` in `When.as_sql()` returns
`("", [])`, then `When.as_sql()` must render the condition as an always-true SQL
predicate before applying the searched-CASE `WHEN ... THEN ...` template.

O2. The chosen always-true predicate must be valid in a `CASE WHEN` condition.
The spec uses `1=1`, matching existing Django expression precedent for an
always-true predicate.

O3. If a `When` condition raises `EmptyResultSet`, `When.as_sql()` must not
catch and reinterpret it as true. `Case.as_sql()` must continue to skip that
case and fall through to the default if no case remains.

O4. If the condition SQL is non-empty, `When.as_sql()` must preserve the
existing template behavior and parameter order: condition parameters first,
then result parameters.

O5. The public API and return shape of `When.as_sql()` must remain unchanged.

## Formal Artifacts

- `fvk/mini-django-case.k` defines the minimal K semantics for the condition
  categories and one-branch searched `CASE` rendering.
- `fvk/django-case-spec.k` contains the reachability claims corresponding to
  O1, O3, and O4.
- `fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
  `fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`, and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` provide the adequacy gate required by
  the FVK method.
