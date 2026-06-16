# FVK Notes

## Decision Summary

V1 stands unchanged. The FVK audit confirms that the source change in
`repo/lib/matplotlib/axes/_axes.py` is the minimal repair required by the public
issue: use an inclusive threshold for `C` mode with explicit `mincnt`, while
preserving the non-empty default for `C` mode when `mincnt` is omitted.

## Decisions Traced to FVK Artifacts

- Kept `len(acc) >= mincnt` in the `C` aggregation path.
  - Justification: `fvk/FINDINGS.md` `FVK-F1` identifies the strict comparator
    as the root bug. `fvk/PROOF_OBLIGATIONS.md` `PO-2` requires explicit
    positive `mincnt` in `C` mode to select bins with `count >= mincnt`.

- Kept the internal `C`-mode omitted-`mincnt` threshold as `1`.
  - Justification: `FVK-F2` confirms that omitted `mincnt` with `C` should keep
    only non-empty bins because arbitrary reducers may not handle empty input.
    `PO-3` formalizes that default as `count >= 1`.

- Made no further change for explicit `mincnt=0` with `C`.
  - Justification: `FVK-F3` classifies this as edge-specified: the issue uses it
    and the requested comparator permits inclusive zero, but the public docstring
    describes the documented parameter as positive. `PO-5` records the reducer
    definedness/NaN frame condition for this edge case.

- Made no public API or wrapper changes.
  - Justification: `PO-6` and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show that the
    V1 patch leaves signatures and `pyplot.hexbin` forwarding unchanged.

- Did not modify tests.
  - Justification: the task forbids test edits. `FVK-F5` records the missing
    public regression coverage as future guidance rather than an action in this
    workspace.

## Verification Status

The FVK proof is constructed, not machine-checked. Per the task constraints, no
tests, Python code, `kompile`, `kast`, or `kprove` commands were executed. The
commands needed for a later machine check are written in `fvk/PROOF.md`.
