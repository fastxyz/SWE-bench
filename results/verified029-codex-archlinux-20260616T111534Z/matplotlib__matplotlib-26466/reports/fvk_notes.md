# FVK Notes

## Decision

V1 is confirmed unchanged. The FVK audit found that the tuple-copy fix satisfies
the public coordinate-aliasing intent for documented two-scalar coordinate
pairs, and no additional source edit is justified.

## Trace to Findings and Proof Obligations

- `repo/lib/matplotlib/text.py`
  - `_AnnotationBase.__init__` remains `self.xy = tuple(xy)`.
  - Justification: F1 is the reported bug, and PO1 proves the stored
    annotation coordinate is framed against later caller-array mutation.

- `repo/lib/matplotlib/text.py`
  - `OffsetFrom.__init__` remains `self._ref_coord = tuple(ref_coord)`.
  - Justification: F2 tracks the public hint that the same issue may exist in
    `OffsetFrom`, and PO2 applies the same snapshot obligation.

- `repo/lib/matplotlib/offsetbox.py`
  - `AnnotationBbox.__init__` remains
    `self.xybox = tuple(xybox) if xybox is not None else self.xy`.
  - Justification: F3 identifies the default `xybox` alias that would remain if
    it used the original `xy` parameter; PO3 proves explicit `xybox` copying and
    defaulting through copied `self.xy`.

- `repo/lib/matplotlib/patches.py`
  - `ConnectionPatch.__init__` remains tuple-copying `xyA` and `xyB`.
  - Justification: F6 classifies this as broader than the exact reproduction
    but compatible with public tuple endpoint stubs; PO4 proves endpoint
    storage independence.

## Rejected Alternative

The public issue hint suggested `np.array(xy)`. F4 and PO5 reject that form for
this codebase because public attributes and tests use tuple-style equality such
as `ann.xy == (x, y)`. `tuple(xy)` both detaches ordinary numeric NumPy arrays
from the caller and preserves tuple-like public behavior.

## Assumptions Preserved

F5 records the scalar-coordinate domain. The proof does not cover nested
mutable coordinate elements, full rendering geometry, transform correctness, or
direct post-construction assignments such as `ann.xy = arr`. Those are outside
the public issue and are not used to justify further edits.

## Execution

No tests, Python code, or K framework tools were run, per task instructions. The
FVK proof is constructed, not machine-checked; the machine-check commands are
recorded in `fvk/PROOF_OBLIGATIONS.md` and `fvk/ITERATION_GUIDANCE.md`.
