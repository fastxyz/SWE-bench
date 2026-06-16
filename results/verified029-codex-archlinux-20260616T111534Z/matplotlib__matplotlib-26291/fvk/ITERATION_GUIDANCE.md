# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

Do not make a V2 source edit. The V1 change in
`repo/lib/mpl_toolkits/axes_grid1/inset_locator.py` already satisfies the proof
obligations:

- PO-002: it resolves `renderer=None` through `ax.figure._get_renderer()`.
- PO-004: it does so before both `get_window_extent` and `get_offset`.
- PO-003: it preserves the provided-renderer path.
- PO-005: it avoids mutating or depending on `self.figure`.
- PO-006: it covers the shared base used by both anchored inset locator classes.

## Rejected Follow-up Changes

- Setting `axes_locator.figure` in `_add_inset_axes` remains rejected. F-001 and
  F-002 show the defect is the missing effective renderer in `__call__`; PO-005
  requires avoiding a dependency on the locator's own `figure`.
- Changing `_tight_bbox.adjust_bbox` remains rejected. E-006 shows
  `locator(ax, None)` is a real caller behavior to support, and PO-002 localizes
  the fallback to the axes-grid locator that needs renderer plumbing.
- Adding broad validation for invalid `ax` objects remains rejected. PO-007
  keeps the formal domain to real axes locator calls; manual invalid calls are
  outside the public contract surfaced by the issue.

## Next Work In An Execution-Enabled Environment

- Run the emitted K commands from `PROOF.md`.
- Run a Matplotlib test that exercises `inset_axes` under `bbox_inches="tight"`
  or the inline backend's equivalent path.
- Add focused regression coverage for `locator(ax, None)` if the project
  maintainers accept new tests. This benchmark task forbids test edits, so no
  test files were changed here.

## Notes For Future Iterations

If future evidence shows a different failure after renderer resolution, localize
it from the new symptom through the extent/offset/transform path. Do not infer
such a failure from the current public issue: the present FVK findings only
justify the V1 renderer fallback.
