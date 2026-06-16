# Iteration Guidance

Status: V1 stands; no production source change is justified by this FVK pass.

## Decision

Keep the current source in `repo/django/db/models/sql/query.py` unchanged.

Rationale:

- F-1 shows the original overlapping `change_map` failure is addressed by
  pre-merge RHS prefix normalization.
- F-2 shows the V1 `exclude` parameter is necessary to preserve the base alias
  required by `combine()`.
- F-3 shows V1 protects the `rhs` non-mutation frame condition by isolating the
  cloned `table_map` lists.
- F-4 shows the added optional argument is compatible with existing
  `bump_prefix()` callers.
- F-5 is a proof/tooling boundary, not a code defect.

## Suggested Follow-Up Tests

Do not edit tests in this benchmark. In a normal Django development pass, add:

- A regression for the exact issue shape: `qs1 | qs2` where RHS has sequential
  aliases and LHS allocation would otherwise produce overlapping replacement
  aliases.
- A commuted-order check that `qs2 | qs1` still works.
- A frame check that using `rhs` in a combine operation does not mutate
  `rhs.table_map` alias lists.
- A compatibility check for existing subquery callers of `bump_prefix()` with
  no `exclude` argument.

## Machine-Check Follow-Up

When a K environment is available, run the commands listed in `fvk/PROOF.md`.
Until they return `#Top`, the proof remains constructed, not machine-checked.

## Residual Risk

This proof abstracts over full SQL generation and database execution. It proves
the alias-map safety property relevant to the reported `AssertionError`, not
semantic equivalence of every possible ORM query. Existing broader ORM tests
should remain in place.
