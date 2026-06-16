# Iteration Guidance

Status: constructed for FVK audit; not machine-checked.

## Code decision

V1 stands unchanged.

The FVK findings and proof obligations identify one source-code defect:
`Patch.draw()` zeroed the stored dash offset before binding the renderer
graphics context. V1 removes that override. No further source edit is justified
by the artifacts.

## Recommended next checks outside this session

1. Machine-check the formal artifacts in an environment with K installed:

   ```sh
   cd fvk
   kompile mini-patch-dash.k --backend haskell
   kast --backend haskell patch-dash-spec.k
   kprove patch-dash-spec.k
   ```

2. Run Matplotlib's public test suite in a normal execution environment.
3. Add or keep tests for:
   - rectangle dash tuple offsets;
   - ellipse dash tuple offsets;
   - image/backend rendering of dashed patch edges.
4. Add a release note if following the normal Matplotlib contribution process.

## No-change rationale

- Do not edit `set_linestyle`: PO-3 shows it already stores the normalized and
  scaled offset.
- Do not edit `set_linewidth`: PO-3 shows it already rescales the stored
  unscaled dash pattern.
- Do not edit backends: F-005 identifies backend rendering as a residual trusted
  component, while the issue's source-localized defect is fixed before the
  backend boundary.
- Do not add a warning: F-003 records the compatibility change and the public
  evidence rejecting preservation of ignored non-zero offsets.
- Do not modify tests in this benchmark phase: F-004 records the test gap while
  respecting the task constraint.
