# FVK Notes

## Decisions

1. V1 was not kept unchanged. `fvk/FINDINGS.md` F2 identified a compatibility
   gap: V1 read generic `GridSpec.wspace` / `GridSpec.hspace`, so
   `add_subfigure(gs[i])` could start treating arbitrary subplot spacing as
   manual subfigure spacing. That conflicted with the public issue discussion
   captured by `fvk/PROOF_OBLIGATIONS.md` PO5.

2. `repo/lib/matplotlib/figure.py` now stores manual subfigure spacing on the
   GridSpec created by `FigureBase.subfigures` as `_subfigure_wspace` and
   `_subfigure_hspace`. This discharges PO1: the source of manual subfigure
   spacing is the `Figure.subfigures(..., wspace=..., hspace=...)` call.

3. `_redo_transform_rel_fig` now reads only `_subfigure_wspace` and
   `_subfigure_hspace`, and falls back from missing/`None` values to `0.0`.
   This discharges PO2 and PO5, fixes F2, and preserves the zero-default
   behavior recorded in F3.

4. The GridSpec-style arithmetic from V1 was retained: average-cell denominators,
   separators, cumulative cell edges, and span min/max bbox extraction. F1 is
   still fixed by this logic, and the retained code discharges PO3 and PO4.

5. The explicit `bbox` branch in `_redo_transform_rel_fig` was left unchanged.
   F5 and PO6 require constrained layout to keep overriding manual placement by
   direct bbox assignment.

6. `FigureBase.subfigures` still passes `wspace` and `hspace` into `GridSpec`.
   This keeps constrained-layout consumers compatible and discharges PO7, while
   the new private `_subfigure_*` metadata separates manual subfigure layout
   from generic subplot spacing.

7. No public signatures or test files were modified. This follows PO8 and the
   task constraint that the hidden/fixed test suite must not be edited.

8. The FVK artifacts name the proof domain rather than expanding the code change
   into new validation behavior for exotic ratios or denominator-zero spacing.
   That decision traces to F4 and PO9: the issue is about ordinary subfigure
   spacing semantics, not new GridSpec input validation.

## Artifacts

The required FVK files are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the adequacy and constructed-K core requested by the FVK docs:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-subfigure-layout.k`
- `fvk/subfigure-layout-spec.k`

No tests, Python, `kompile`, `kast`, or `kprove` were run.
