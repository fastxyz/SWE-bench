# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: Preserve range while adding density

- Intent: I-001, I-002.
- Claim: `hist-range-density`.
- Precondition: `lo < hi`, `inputEmpty=False`, `nx=1`, `density=True`,
  `normed=False`, `stacked=False`.
- Required postcondition: kwargs are
  `kw(true, range(lo, hi), true, true)`.
- Status: discharged by V1. `initKwargs` sets range, and `addDensity` updates
  the density fields without changing `hasRange` or `rangeValue`.
- Finding link: F-001.

## PO-002: Preserve non-density range behavior

- Intent: I-003.
- Claim: `hist-range-no-density`.
- Precondition: `lo < hi`, `inputEmpty=False`, `nx=1`, `density=False`,
  `normed=False`, `stacked=False`.
- Required postcondition: kwargs are
  `kw(true, range(lo, hi), false, false)`.
- Status: discharged by V1. The density branch is skipped, so the range-only
  kwargs are preserved.
- Finding link: F-001, F-004.

## PO-003: Preserve stacked density manual normalization

- Intent: I-005.
- Claim: `hist-stacked-frame`.
- Precondition: `lo < hi`, `inputEmpty=False`, `nx=1`, effective density true,
  `stacked=True`.
- Required postcondition: kwargs include range but do not include density.
- Status: discharged by V1. The density update is guarded by `not stacked`.
- Finding link: F-002.

## PO-004: Preserve multiple-dataset shared-bin routing

- Intent: I-006.
- Claim: `hist-multi-density-frame`.
- Precondition: `lo < hi`, `inputEmpty=False`, `nx=2`, `density=True`,
  `normed=False`, `stacked=False`.
- Required postcondition: per-dataset histogram kwargs include density and omit
  range because range was already used by `histogram_bin_edges`.
- Status: discharged by V1. The multiple-dataset branch still bypasses the
  `hist_kwargs['range']` assignment and V1 still adds density for non-stacked
  density histograms.
- Finding link: F-003.

## PO-005: Deprecated normed follows effective density

- Intent: I-004.
- Claim: `hist-range-normed`.
- Precondition: `lo < hi`, `inputEmpty=False`, `nx=1`, `density=False`,
  `normed=True`, `stacked=False`.
- Required postcondition: kwargs include both range and density.
- Status: discharged by V1 because `density = bool(density) or bool(normed)`
  runs before the guarded kwargs update.
- Finding link: F-001.

## PO-006: Adequacy and compatibility gate

- Intent: all entries in `fvk/INTENT_SPEC.md`.
- Required postcondition: every formal claim paraphrase is entailed by public
  intent, and no changed public API or unhandled override exists.
- Status: pass. See `fvk/SPEC_AUDIT.md` and
  `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
- Finding link: F-004 for proof-scope limits.
