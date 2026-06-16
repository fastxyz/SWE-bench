# Intent Spec

Status: constructed from public issue evidence; no tests, Python, or K tooling
were run.

## Required behavior

1. A figure that is pickled while displayed on a high-DPI canvas must not encode
   the backend-applied device-pixel-ratio DPI multiplier as permanent figure
   DPI.

2. Repeated pickle/load cycles on the same high-DPI backend must be idempotent
   for live figure DPI. If a figure starts a cycle with live DPI `D = L * R`,
   where `L` is logical figure DPI and `R` is the backend device pixel ratio,
   then after loading and reattaching to a backend with ratio `R`, the live DPI
   must again be `D`, not `D * R`.

3. The fix must apply to high-DPI-capable backends generally, not only to the
   macOS backend, because the public hint says the defect can affect anything
   that knows how to deal with high-DPI screens.

4. Ordinary non-high-DPI figure pickling must preserve the current user-visible
   figure DPI. A figure whose canvas ratio is `1` must serialize `_dpi` as its
   current `_dpi`, even if `_original_dpi` differs because the user changed DPI
   after figure creation.

5. A figure unpickled from normalized state must have DPI-dependent transforms
   consistent with the restored `_dpi` before any GUI backend is attached.

## Out of scope or residual

1. Termination and performance are not proved; the audited functions have no
   loops in the changed path.

2. The mini-K model represents DPI and device-pixel ratio as exact positive
   integer scalars to model the reported doubling failure. The source uses
   Python numeric values and can support non-integer ratios; extending the model
   to exact rationals or real floats is a proof-capability extension, not a
   code change derived by this audit.
