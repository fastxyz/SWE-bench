# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Keep the V1 core fix and apply the V2 helper guard.

- Keep: early expression branch in `find_ordering_name()` because it discharges
  F1 and PO1.
- Keep: alias-relative plain `F()` resolution because it discharges PO3 and
  prevents related expressions from resolving against the root model.
- Keep: top-level-compatible wrapping/reversal behavior because it discharges
  PO2 and PO4.
- Add: non-source child guard because F2 showed V1 assumed too much about every
  expression child.

## Follow-Up Tests to Add When Test Editing Is Allowed

1. Multi-table inheritance or reverse one-to-one relation ordered by the parent
   relation where the child/related model has `Meta.ordering` containing
   `OrderBy(F('child_field'))`.
2. Same shape with `Lower('child_field')`.
3. Same shape with `order_by('-relation')` to assert reversal.
4. Optional broader-expression test with `Case(When(...))` if the project wants
   full alias-relative conditional-expression support.

## Follow-Up Formal Work

If the conditional-expression family is required, extend the spec and code to
represent alias-relative resolution for `Q` lookup strings. Do not certify that
case from the current proof, because PO8 is explicitly outside the proven
domain.

## Commands for Future Machine Check

```sh
kompile fvk/mini-django-ordering.k --backend haskell
kast --backend haskell fvk/django-ordering-spec.k
kprove fvk/django-ordering-spec.k
```

The current session must not run those commands.
