# FVK Findings

Status: constructed, not machine-checked.

## F1: Reported UniqueConstraint failure is fixed

Input: model field `slug` with
`UniqueConstraint(fields=["slug"], name="...")`, then
`Article.objects.in_bulk(field_name="slug")`.

Observed in pre-fix issue: `ValueError` saying `slug` is not a unique field.

Expected from public intent: the call should pass validation because `slug` is
globally unique by a total single-field `UniqueConstraint`.

V2 status: fixed. `QuerySet.in_bulk()` now accepts a non-primary-key field when
the resolved field is covered by a single-field constraint in
`opts.total_unique_constraints`.

Linked obligations: PO1, PO2, PO5.

## F2: V1 attname completeness gap is resolved

Input: relation field `author` whose database column is addressed as
`author_id`, with a total single-field `UniqueConstraint` declared using the
attname, then `in_bulk(field_name="author_id")`.

Observed in V1 reasoning: V1 compared only `field.name` with the constraint
field identifier. That accepted constraints declared as `author` but did not
explicitly cover the identifier form `author_id`, even though Django local
field validation indexes both names.

Expected from public code evidence: the same concrete field should be
recognized whether a valid constraint field identifier names `author` or
`author_id`.

V2 status: fixed. The check now compares the one-field constraint identifier
against `{field.name, field.attname}`.

Linked obligations: PO3, PO4.

## F3: Composite UniqueConstraints remain rejected

Input: `UniqueConstraint(fields=["slug", "site"], name="...")`, then
`Article.objects.in_bulk(field_name="slug")`.

Observed if accepted: multiple rows could share the same `slug` with different
`site` values, so the returned dictionary could overwrite objects for a single
key.

Expected from the `in_bulk()` contract: a single `field_name` key must identify
at most one row. A composite constraint proves uniqueness only for the tuple,
not for any individual member.

V2 status: correctly rejected. The code only accepts constraints with
`len(constraint.fields) == 1`.

Linked obligations: PO2, PO6.

## F4: Conditional UniqueConstraints remain rejected

Input: `UniqueConstraint(fields=["slug"], condition=Q(active=True), ...)`,
then `in_bulk(field_name="slug")`.

Observed if accepted: rows outside the condition could duplicate the same
`slug`, so the single dictionary key would not be globally unique.

Expected from the issue phrase "total UniqueConstraints" and
`Options.total_unique_constraints`: only unconditional constraints qualify.

V2 status: correctly rejected. The code uses `opts.total_unique_constraints`,
which excludes conditional constraints.

Linked obligations: PO2, PO6.

## F5: No tests or code execution were run

Input: this benchmark session.

Observed: no tests, Python code, `kompile`, or `kprove` were executed.

Expected from the task: reason about expected outcomes and write artifacts
instead of executing commands.

V2 status: complied. The proof is constructed, not machine-checked.

Linked obligations: PO7.
