# FVK Iteration Guidance

Status: V2 confirms the V1 implementation behavior and adds one documentation
improvement.

## Code Guidance

Keep the V1 source behavior for `_process_contour_level_args`.  Findings F-001,
F-002, F-003, and F-004 are discharged by PO-1 through PO-6.

The only V2 source change is the docstring update required by F-005 and PO-7.
No further production-code edit is justified by the current public intent.

Do not extend the patch to `tricontour` in this task.  F-006 and PO-9 record
that triangular contours are outside the reported 2D-array `contour`/`contourf`
scope.  If future public intent requests parity there, add a separate
obligation rather than smuggling it into this fix.

## Suggested Tests For A Real Test Environment

Do not add tests in this benchmark task.  In a normal development environment,
the following public tests would be useful:

- `ax.contour(bool_grid).levels` equals `[0.5]`.
- `ax.contourf(bool_grid).levels` equals `[0, 0.5, 1]`.
- `ax.contour(all_false_bool_grid).levels` still equals `[0.5]`.
- `ax.contour(bool_grid, levels=[0, 1]).levels` preserves the explicit levels.
- `ax.contour(np.array(bool_grid, dtype=float)).levels` follows the numeric
  automatic path, not the boolean default.

## Machine-Check Guidance

The constructed K commands in `fvk/PROOF_OBLIGATIONS.md` and `fvk/PROOF.md`
should be run in an environment with K installed before treating the formal
claims as machine-verified.

Until then, keep any existing tests.  The proof is constructed, not
machine-checked, and this task forbids executing the suite.

## UltimatePowers-Style Clarification If Scope Expands

If a future issue asks about related APIs, ask: "Should boolean defaults also
apply to `tricontour`/`tricontourf`, whose `z` input is not the 2D boolean array
path described here?"
