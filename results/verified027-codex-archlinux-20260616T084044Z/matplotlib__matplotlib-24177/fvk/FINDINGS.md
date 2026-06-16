# FVK FINDINGS: matplotlib__matplotlib-24177

Status: constructed, not machine-checked.

## F-001: Legacy default path simplification under-approximates step polygon limits

- Classification: code bug in the pre-V1 behavior; resolved by V1.
- Evidence: problem hint shows a step-path vertex maximum of
  `[4.93527997, 0.33418844]`, while default `path.iter_segments()` yields a
  much smaller subset that omits that y maximum.
- Input: a long straight-line step histogram polygon, such as the public
  65-bin example.
- Observed before V1: `_update_patch_limits` called `p.iter_bezier()` with
  default `simplify=None`, so `iter_segments()` could use path simplification
  and omit vertices needed for data limits.
- Expected: data limits are computed from the full data geometry, including
  the maximum density vertex.
- Proof obligations: PO-1, PO-2, PO-3, PO-4.
- Resolution: V1 passes `simplify=False` to `iter_bezier`, disabling path
  simplification for data-limit computation.

## F-002: V1 preserves Bezier extrema behavior while fixing line simplification

- Classification: positive verification finding; no source change required.
- Evidence: `_update_patch_limits` still calls `axis_aligned_extrema()` for
  every Bezier segment and appends `curve([0, *dzeros, 1])`.
- Input: a finite patch path with straight lines or Bezier curves.
- Observed in V1: the only changed behavior is the iterator cleanup option;
  endpoints and interior curve extrema are still collected.
- Expected: the fix should not regress curve limit handling.
- Proof obligations: PO-2, PO-3, PO-5.
- Resolution: keep V1 unchanged.

## F-003: V1 fixes the reported histogram step autoscale path for both orientations

- Classification: positive verification finding; no source change required.
- Evidence: `Axes.hist` step mode constructs `xvals` and `yvals` from every bin
  edge and top; horizontal orientation swaps the arrays before the patch is
  created.
- Input: finite density histogram with `histtype="step"` and vertical or
  horizontal orientation.
- Observed in V1: every original step-outline vertex remains available to
  `_update_patch_limits`, so the maximum density coordinate is passed to
  `update_datalim` on the relevant axis.
- Expected: the density axis autoscale includes the whole histogram outline.
- Proof obligations: PO-1, PO-3, PO-4.
- Resolution: keep V1 unchanged.

## F-004: Residual proof boundary: full Matplotlib/Python semantics are abstracted

- Classification: proof capability gap, not a source bug for this issue.
- Evidence: the FVK proof uses a small abstract semantics for path iteration,
  candidate point construction, and data-limit update. It does not model all
  NumPy array operations, all transforms, all backends, or all possible patch
  subclasses.
- Input: cases outside the audited domain, especially arbitrary non-affine
  transformed curve extrema unrelated to the reported step-histogram polygon.
- Observed: not machine-checked and not modeled at full Matplotlib scope.
- Expected: do not use this constructed proof to remove broad integration
  tests or to claim full-library verification.
- Proof obligations: PO-6, PO-7.
- Resolution: no code edit; keep existing broader tests. This boundary does
  not block V1 for the reported step-histogram autoscale bug.

## F-005: No public compatibility blocker

- Classification: compatibility finding; no source change required.
- Evidence: V1 changes no public signature and calls an existing documented
  `iter_segments` keyword through `iter_bezier(**kwargs)`.
- Input: public callers of histogram, patches, and path APIs.
- Observed in V1: public call shapes and return values are unchanged.
- Expected: no public API migration is required.
- Proof obligations: PO-5.
- Resolution: keep V1 unchanged.

## F-006: Tests and K tooling were not run

- Classification: process finding.
- Evidence: benchmark instructions forbid tests, Python execution, and K
  tooling in this session.
- Input: the constructed proof and local source diff.
- Observed: proof and expected outcomes are reasoned from source and public
  issue evidence only.
- Expected: artifacts must be labeled "constructed, not machine-checked"; no
  test deletion is recommended without later machine checking and normal test
  execution.
- Proof obligations: PO-7.
- Resolution: no source edit; retain the honesty caveat.
