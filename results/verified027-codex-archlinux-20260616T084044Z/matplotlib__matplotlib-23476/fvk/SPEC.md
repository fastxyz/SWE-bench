# FVK Spec

Status: constructed, not machine-checked.

## Unit Under Audit

Primary source unit: `repo/lib/matplotlib/figure.py`, methods
`Figure.__getstate__` and `Figure.__setstate__`.

Supporting source units:

- `repo/lib/matplotlib/backend_bases.py`, `FigureCanvasBase.__init__`,
  `FigureCanvasBase._set_device_pixel_ratio`, and `FigureCanvasBase.print_figure`
- `repo/lib/matplotlib/artist.py`, `Artist.__getstate__`

There are no loops in the changed methods. The proof obligations are function
contracts over serialized figure state and backend reattachment state.

## State Model

Let:

- `L` be logical figure DPI, represented in source by `_original_dpi` while a
  high-DPI canvas is active.
- `R` be `canvas.device_pixel_ratio`.
- `D` be live runtime `figure._dpi`.
- `T` be the scale encoded by `figure.dpi_scale_trans`.

For high-DPI runtime state, the source relation is:

```text
D = L * R
R != 1
```

For ordinary non-high-DPI state:

```text
R = 1
D is the current user-visible figure DPI
```

The mini-K model represents `D`, `L`, `R`, and `T` as exact positive integer
scalars. This directly covers the reported M1 doubling case (`R = 2`) and the
proof structure for multiplicative scaling. It is not a machine-checked proof
over Python floats.

## Public Intent Ledger

The full ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`.

- E1/E2/E5 require repeated high-DPI pickle/load cycles to preserve live DPI
  rather than multiplying it again.
- E4 requires a backend-neutral repair.
- E6/E8 identify `_original_dpi` as the logical DPI already used by high-DPI
  backend and savefig paths.
- E9/E10 require handling both `_dpi` and DPI transform state, because both are
  part of figure pickle state.
- E11 requires preserving public method signatures and dispatch shape.

## Formal Contract Summary

O1. High-DPI serialization:

For `R != 1` and `D = L * R`, `Figure.__getstate__` serializes `_dpi` as `L`.
It does not serialize `D` as permanent figure DPI.

O2. Ordinary serialization frame condition:

For `R = 1`, `Figure.__getstate__` serializes `_dpi` as current `D`, not
unconditionally as `_original_dpi`.

O3. Base unpickle state:

After `Figure.__setstate__` loads a pickle whose stored `_dpi` is `P`, the
figure has `_dpi = P`, `_original_dpi = P` after `FigureCanvasBase(self)`, and
`dpi_scale_trans` scaled by `P`.

O4. High-DPI roundtrip idempotence:

For `R != 1` and initial high-DPI state `D = L * R`, a getstate/setstate/backend
reattach cycle on a backend with the same ratio `R` yields live DPI `L * R`,
not `L * R * R`.

O5. Transform consistency:

Unpickling from normalized state leaves the DPI transform consistent with the
restored `_dpi`; after backend reattachment with ratio `R`, backend `_set_dpi`
again makes the transform consistent with live `_dpi`.

O6. Compatibility:

The repair does not change public method signatures, return shape, or virtual
dispatch protocol for `Figure.__getstate__`, `Figure.__setstate__`, or canvas
device-pixel-ratio handling.

## Formal Files

- `fvk/mini-python-figure-pickle.k`: mini-K state-transition model.
- `fvk/figure-pickle-spec.k`: K claims for O1-O5.

Exact commands to machine-check later are listed in `fvk/PROOF.md`.
