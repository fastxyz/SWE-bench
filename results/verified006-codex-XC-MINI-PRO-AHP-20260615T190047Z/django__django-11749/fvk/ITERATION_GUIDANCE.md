# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No source edit is justified by the FVK audit. The public defect is F-001, and
V1 discharges it through PO-003 while preserving the frame conditions in PO-004,
PO-005, PO-006, and PO-007.

## Recommended Tests For A Future Test Pass

Do not add tests in this task, because the instructions forbid modifying test
files. For a future normal Django development pass, add focused tests for:

- `call_command(command, shop_id=1)` where `shop_id` is in a required mutually
  exclusive group;
- the alternate group member, for example `shop_name='store'`;
- missing group kwargs still raising the required-group error;
- both group kwargs still raising a mutual-exclusion conflict;
- a required option whose supplied kwarg is normalized through `arg_options`.

## Future Work Not Required By This Issue

- A full formal model of Python `argparse` would reduce F-004, but the correct
  source design here is to keep delegating validation to argparse.
- Broader support for unusual custom argparse actions can be considered if a
  public issue reports them. The current public issue uses ordinary optional
  actions with scalar values.
- The K artifacts should be machine-checked in an environment with K installed
  before any test-removal recommendation is acted on.
