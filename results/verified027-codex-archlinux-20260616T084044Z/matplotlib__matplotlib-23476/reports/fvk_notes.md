# FVK Notes

Status: FVK pass constructed only. I did not run tests, Python, `kompile`,
`kast`, or `kprove`.

## Decisions

V1 stands unchanged. The FVK audit found that the existing source edit in
`repo/lib/matplotlib/figure.py` satisfies the proof obligations derived from
the public issue.

## Source Decision Trace

`Figure.__getstate__`

- Kept V1's `device_pixel_ratio != 1` guard.
- Justification: F1 and O1/O4 require high-DPI pickles to store logical DPI so
  same-backend reload does not produce `L * R * R`. F2 and O2/O5 require the
  same change not to affect ratio-1 figures, where current `_dpi` must be
  preserved even if `_original_dpi` differs.
- Rejected alternative: unconditionally serializing `_original_dpi`; F2 shows
  it would lose ordinary user DPI changes.

`Figure.__setstate__`

- Kept V1's `dpi_scale_trans.clear().scale(self._dpi)` resync.
- Justification: F3 and O3 show that `_dpi` can be normalized while the raw
  pickled `dpi_scale_trans` still reflects high-DPI runtime scale. The transform
  must be rebuilt from restored `_dpi` before backend reattachment.
- Rejected alternative: relying on the pickled transform object unchanged; F3
  shows this can leave `fig.dpi` and DPI transforms inconsistent.

No backend-specific source file was changed.

- Justification: F1/O1 and E4 in the public evidence ledger require a
  backend-neutral fix because the public hint says high-DPI-aware backends in
  general can be affected. `Figure.__getstate__`/`__setstate__` are the shared
  serialization boundary.

No public API or dispatch compatibility source edit was needed.

- Justification: F4 and O6 found no changed signatures, return shapes, or new
  virtual-dispatch arguments.

## Artifact Decisions

Created the required FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Created supporting FVK contract artifacts required by the kit:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-figure-pickle.k`
- `fvk/figure-pickle-spec.k`

## Residual Risk

F5/O7 records the main residual limitation: the constructed mini-K proof models
DPI and device pixel ratio as positive integer scalars. This is adequate for
the reported ratio-2 doubling mechanism but is not a machine-checked proof over
all Python numeric values or non-integer display ratios.

All test-redundancy claims remain conditional on later machine-checking. No
test files were modified.
