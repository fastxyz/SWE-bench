# FVK Findings

Status: constructed, not machine-checked. Findings are derived from the public
issue, source inspection, and formal proof obligations only.

## F-001: Pre-V1 locator forwarded `renderer=None` into `OffsetBox`

- Classification: code bug, resolved by V1.
- Evidence: E-001, E-003, E-006, E-007.
- Obligation: PO-001, PO-002.
- Input: an `AnchoredSizeLocator` installed by `inset_axes`, called as
  `locator(ax, None)` from `_tight_bbox.adjust_bbox`.
- Pre-V1 observed behavior: `OffsetBox.get_window_extent(None)` attempted
  `self.figure._get_renderer()` even though the locator is not a figure-owned
  artist, producing `AttributeError`.
- Expected behavior: resolve a renderer and return a bbox for the inset axes.
- V1 status: resolved. `AnchoredLocatorBase.__call__` now resolves
  `renderer = ax.figure._get_renderer()` before calling `get_window_extent`.

## F-002: Renderer-sensitive offset/size calculations need the same fallback

- Classification: code bug, resolved by V1.
- Evidence: E-004, E-008.
- Obligation: PO-004.
- Input: the same `locator(ax, None)` path after any hypothetical fix that only
  gave `OffsetBox` a figure.
- Pre-V1 / partial-fix observed behavior by source reasoning:
  `AnchoredSizeLocator.get_bbox` and `AnchoredOffsetbox.get_offset` require a
  renderer with `points_to_pixels`.
- Expected behavior: all extent, size, and offset steps use a non-`None`
  effective renderer.
- V1 status: resolved. The fallback is before both `get_window_extent` and
  `get_offset`.

## F-003: No public API or dispatch compatibility problem

- Classification: compatibility confirmation.
- Evidence: E-005, E-009.
- Obligation: PO-003, PO-005, PO-006.
- Input: public callers using `inset_axes(...)`, `zoomed_inset_axes(...)`, or an
  axes locator callable with the existing `(ax, renderer)` signature.
- Observed V1 behavior by source reasoning: the signature, return type, and
  public constructors remain unchanged; only the internal `None` renderer branch
  has a new fallback.
- Expected behavior: no public callsite or subclass override update required.
- V1 status: confirmed.

## F-004: No further source revision justified

- Classification: V1 confirmation.
- Evidence: E-001 through E-009.
- Obligation: PO-001 through PO-007.
- Input: in-domain calls to `AnchoredLocatorBase.__call__(ax, renderer)` where
  `renderer` is either provided or `None`.
- Observed V1 behavior by proof construction: provided-renderer calls follow the
  original path; `None`-renderer calls first obtain `ax.figure._get_renderer()`;
  both paths use a non-`None` renderer for extent and offset calculations.
- Expected behavior: same as the intent contract in `SPEC.md`.
- V1 status: confirmed unchanged.

## F-005: Proof and tests remain unexecuted by instruction

- Classification: proof/tooling limitation, not a code bug.
- Evidence: task instructions prohibit tests, Python execution, and K tooling.
- Obligation: PO-008.
- Input: any proposed test-redundancy or machine-check claim.
- Observed status: proof is constructed but not machine-checked; no tests were
  run.
- Expected handling: keep all tests; run the emitted `kompile` / `kprove`
  commands and normal Matplotlib tests only in an environment where execution is
  allowed.
