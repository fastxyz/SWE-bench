# FVK Findings

Status: constructed, not machine-checked. Findings are based on public intent,
source inspection, and the constructed proof obligations; no tests or code were
run.

## F1: Empty full-predicate condition produced invalid searched CASE SQL

- Classification: code bug in pre-V1 behavior, closed by V1.
- Evidence: public issue reports `CASE WHEN THEN True ELSE False END` and a
  database syntax error near `THEN`.
- Input: `Case(When(~Q(pk__in=[]), then=Value(True)), default=Value(False))`.
- Observed before V1: `WhereNode.as_sql()` returned `("", [])` for the
  always-true condition, and `When.as_sql()` inserted the empty string into
  `WHEN %(condition)s THEN ...`.
- Expected: a valid searched `CASE` whose condition is true for every row and
  whose branch result is `True`.
- Related obligations: O1, O2, O4 in `PROOF_OBLIGATIONS.md`.
- V1 status: closed. `When.as_sql()` now rewrites the empty full-predicate
  condition to `1=1`, so the rendered fragment becomes
  `WHEN 1=1 THEN True`.

## F2: Impossible empty predicates must remain false/fall-through

- Classification: compatibility/frame condition, satisfied by V1.
- Evidence: public test `test_annotate_with_empty_when` expects
  `When(pk__in=[])` to fall through to the default.
- Input: `Case(When(pk__in=[], then=Value("selected")), default=Value("not selected"))`.
- Expected: default value is selected.
- V1 status: satisfied. V1 only handles the `condition_sql == ""` full-result
  return path. It does not catch `EmptyResultSet`, so `Case.as_sql()` continues
  to skip impossible cases.
- Related obligations: O3 in `PROOF_OBLIGATIONS.md`.

## F3: Non-empty predicate rendering and API compatibility are preserved

- Classification: compatibility/frame condition, satisfied by V1.
- Evidence: `When.as_sql()` signature and return shape are unchanged; the V1
  branch only changes the empty condition string.
- Input class: any `When` whose condition compiles to a non-empty predicate SQL
  fragment.
- Expected: existing SQL template and parameter ordering are preserved.
- V1 status: satisfied by inspection.
- Related obligations: O5, O6 in `PROOF_OBLIGATIONS.md`.

## F4: Residual verification risk

- Classification: proof capability and execution boundary, not a source bug.
- Evidence: FVK proof is constructed but not machine-checked, and the mini-K
  fragment abstracts the full Django ORM and database backends.
- Expected follow-up: keep existing tests and add/keep integration coverage for
  the issue until the emitted K commands and Django tests can be run in an
  environment that supports them.
- Related obligations: O7, O8 in `PROOF_OBLIGATIONS.md`.

No open FVK finding justifies a source change beyond V1.
