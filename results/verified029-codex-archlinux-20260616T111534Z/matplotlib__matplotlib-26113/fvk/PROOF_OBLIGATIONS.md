# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Bin Cardinality Correspondence

- Statement: For every real bin `b`, the count-only branch's `accum[b]` equals
  the length of the `C` branch's accumulator list for `b`.
- Evidence: `i1`, `i2`, and `bdist` are computed before the branch split; both
  branches drop sentinel index `0` for out-of-range points.
- Proof sketch: induction over input point index `i`. Each point contributes
  exactly one count increment in the count-only model and exactly one append in
  the `C` model at the same real bin, or both contributions go to sentinel bin
  `0` and are later dropped.
- Status: discharged by source-level reasoning; not represented in
  `mini-hexbin.k`.

## PO-2: Explicit Positive `mincnt` Is Inclusive in `C` Mode

- Statement: For `M >= 1`, `C` mode selects a bin iff `count[b] >= M`.
- Evidence: issue requests `len(vals) >= mincnt`; V1 uses
  `len(acc) >= mincnt`.
- K claim: `CLAIM-C-EXPLICIT`.
- Status: discharged by `CLAIM-LOOP` plus `threshold(cMode, some(M)) => M`.

## PO-3: Omitted `mincnt` in `C` Mode Keeps Non-Empty Bins

- Statement: `C` mode with `mincnt=None` selects a bin iff `count[b] >= 1`.
- Evidence: issue accepts this default because reducers need not handle empty
  input.
- K claim: `CLAIM-C-DEFAULT`.
- Status: discharged by `threshold(cMode, none) => 1`.

## PO-4: Count-Only Behavior Is Preserved

- Statement: count-only explicit positive `mincnt=M` selects bins with
  `count[b] >= M`; omitted `mincnt` selects all finite bins.
- Evidence: issue describes this as the intuitive baseline.
- K claims: `CLAIM-COUNT-EXPLICIT`, `CLAIM-COUNT-DEFAULT`.
- Status: discharged; V1 does not change count-only source logic except the
  docstring wording.

## PO-5: Reducer Definedness and NaN Frame

- Statement: The threshold proof determines which bins are eligible for
  reduction. The final observable collection still excludes bins whose reduced
  value is NaN via `good_idxs = ~np.isnan(accum)`.
- Evidence: source code after both branches applies the same NaN filter.
- Status: frame condition. For explicit `mincnt=0` in `C` mode, callers need a
  reducer that is defined on empty input and returns a non-NaN value if they
  expect empty bins to be displayed.

## PO-6: Public Compatibility

- Statement: V1 must not alter signatures, dispatch shape, or pyplot forwarding.
- Evidence: only comparator/default-threshold lines and docstring wording
  changed in `Axes.hexbin`; `pyplot.hexbin` still forwards `mincnt`.
- Status: discharged by source audit in `PUBLIC_COMPATIBILITY_AUDIT.md`.

## PO-7: Termination Boundary

- Statement: The modeled selection loop processes a finite count list.
- Evidence: the real code builds finite arrays/lists from finite `x`, `y`, and
  `C` inputs.
- Status: partial correctness proof assumes return; total correctness is not
  machine-proved. The loop structurally consumes one list item per step.
