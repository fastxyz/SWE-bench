# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source change in `repo/lib/matplotlib/offsetbox.py`. The FVK audit
found that V1 discharges PO-1 through PO-7 for the public issue intent.

## Do not change

- Do not propagate the `AnnotationBbox` gid to the contained `OffsetImage`,
  `BboxImage`, arrow patch, or frame patch. PO-6 requires the parent gid to
  identify the parent group without duplicate SVG ids.
- Do not move `open_group` before the existing visibility and `_check_xy`
  guard. PO-3 preserves skipped-annotation behavior and avoids empty groups.
- Do not alter SVG backend image emission for this issue. F-001 localizes the
  missing gid to the parent annotation's draw method, not to image drawing.
- Do not change public method signatures or child draw call signatures. PO-5
  confirms the existing renderer API is sufficient.

## Possible future work outside this fix

- Add a public SVG test for `AnnotationBbox` gid grouping. F-004 identifies the
  gap, but test files are fixed for this task.
- Consider a project-wide policy for `try/finally` around renderer groups if
  exception-path writer balance is important. F-003 records this as residual
  risk, not as a bug in the issue fix.
- If generated no-gid group names ever become public API, specify their spelling
  explicitly. F-002 currently treats that spelling as under-specified and
  non-blocking.
