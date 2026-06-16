# Formal Spec English

Status: constructed, not machine-checked.

## Claim SKIPPED-UNDER-PDB

Starting with any nonnegative delayed-teardown count and any explicit slot
contents, after `setup`, a `--pdb` unittest run in which unittest does not call
`tearDown`, and pytest item teardown, the explicit slot is `none` and the
delayed-teardown count is unchanged.

## Claim REACHED-TEARDOWN-UNDER-PDB

Starting with any nonnegative delayed-teardown count and any explicit slot
contents, after `setup`, a `--pdb` unittest run in which unittest does call
`tearDown`, and pytest item teardown, the explicit slot is `none` and the
delayed-teardown count has increased by exactly one.

## Claim NO-PDB-NO-DELAYED-CALL

Starting with any nonnegative delayed-teardown count and any explicit slot
contents, after `setup`, a non-`--pdb` unittest run, and pytest item teardown,
the explicit slot is `none` and the delayed-teardown count is unchanged. This
claim tracks only pytest's delayed-teardown mechanism, not unittest's direct
non-`--pdb` call to `tearDown`.

## No Loop Or Recursion Circularities

The audited code path has no loop or recursion. The proof obligations are
straight-line reachability claims over a small state machine.
