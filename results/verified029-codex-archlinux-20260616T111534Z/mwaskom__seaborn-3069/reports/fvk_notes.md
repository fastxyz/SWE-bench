# FVK Notes

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`,
or `kprove` were run.

## Decision

V1 stands unchanged. The FVK audit did not surface a source bug justified by the
public issue intent.

## Trace from findings and obligations

- No code change for default nominal x/y bounds: `fvk/FINDINGS.md` F1 confirms
  the V1 branch satisfies `fvk/PROOF_OBLIGATIONS.md` O3 and O4 by disabling the
  nominal grid and setting x/y categorical half-step limits.
- No code change for inferred nominal scales: F2 confirms O1 and O7 because V1
  checks the compiled scale in `self._scales`, so explicit `so.Nominal()` and
  inferred nominal coordinate scales follow the same path.
- No code change for explicit nominal y limits: F3 confirms O5. The public
  issue requires nominal y inversion, but it does not justify discarding
  explicit `Plot.limit(...)`; V1 applies the user limit and then ensures the y
  axis is inverted.
- No code change for empty nominal axes: F4 records an under-specified boundary.
  O2 requires category counting for meaningful default bounds, and V1 avoids
  setting default categorical limits when the count is not positive.
- No code change for `_nominal_axis_length`: F5 records the Matplotlib unit
  mapping as an integration proof boundary, not a contradiction. O2 is still
  discharged by using the category mapping when present and the categorical
  tick-count approach as fallback.
- No compatibility edit: O8 and `fvk/PUBLIC_COMPATIBILITY_AUDIT.md` show the
  public `Plot` API, `_finalize_figure` call signature, and objects namespace
  remain unchanged.

## Artifacts

The requested artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Supporting FVK adequacy and formal-core artifacts are also present:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-axis.k`
- `fvk/nominal-axis-spec.k`

## Residual risk

The proof is constructed against a small axis-state model and abstracts
Matplotlib internals. Test removal is not recommended. Future tests should keep
checking rendered Matplotlib axes for inferred nominal scales, grid visibility,
facets/pairing, and explicit limits.
