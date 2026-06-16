# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public
intent, source inspection, and proof-obligation construction only.

## F1: Resolved Code Bug - High-DPI Runtime DPI Was Serialized as Permanent DPI

Input/state:

```text
logical DPI L = 100
device pixel ratio R = 2
live figure DPI D = 200
```

Observed pre-fix behavior:

```text
pickle stores _dpi = 200
unpickle treats 200 as new _original_dpi
backend applies R = 2
next live DPI = 400
```

Expected behavior:

```text
pickle stores logical _dpi = 100
unpickle treats 100 as _original_dpi
backend applies R = 2
next live DPI = 200
```

V1 status: resolved by `Figure.__getstate__` normalizing `_dpi` to
`_original_dpi` when `canvas.device_pixel_ratio != 1`.

Proof obligations: O1, O4.

## F2: Resolved Compatibility Risk - `_original_dpi` Must Not Be Used Unconditionally

Input/state:

```text
ratio R = 1
current figure DPI D = 200
old original DPI O = 100
```

Bug that an over-broad fix would introduce:

```text
pickle stores _dpi = 100
load loses the user's current DPI 200
```

Expected behavior:

```text
pickle stores _dpi = 200
load preserves current DPI 200
```

V1 status: resolved by the `device_pixel_ratio != 1` guard.

Proof obligations: O2, O5.

## F3: Resolved State-Consistency Risk - DPI Transform Must Match Restored `_dpi`

Input/state:

```text
raw high-DPI pickle state has stored _dpi = 100
raw dpi_scale_trans may still encode scale 200 from the live canvas
```

Potential bug:

```text
fig.dpi reports 100, but bbox and DPI transforms still use stale scale 200
before backend reattachment
```

Expected behavior:

```text
after __setstate__, dpi_scale_trans is rescaled to restored _dpi = 100
```

V1 status: resolved by `self.dpi_scale_trans.clear().scale(self._dpi)` in
`Figure.__setstate__`.

Proof obligations: O3, O5.

## F4: No Public Compatibility Break Found

V1 changes no public method signatures and adds no new virtual-dispatch
arguments. The pickle state remains a dictionary. The only storage semantic
change is the intended replacement of high-DPI runtime `_dpi` with logical
`_dpi`.

Proof obligation: O6.

## F5: Residual Proof Capability Gap - Numeric Model Is Integer-Scalar

The constructed K model uses positive integers for DPI and device pixel ratio.
That directly models the reported doubling path (`R = 2`) and the algebraic
reason repeated multiplication is removed. It is not a machine-checked proof
over arbitrary Python floats or non-integer display ratios.

Classification: proof capability gap, not a code bug.

Proof obligation: O7.

## Proof-Derived Findings From `/verify`

No additional code bug was found while constructing the proof obligations. The
proof confirms V1's two critical design choices:

- Normalize only when `device_pixel_ratio != 1` (F2).
- Resync `dpi_scale_trans` after restoring state (F3).

Because O1-O6 are covered by V1 source behavior, no source edit is justified by
this FVK pass.
