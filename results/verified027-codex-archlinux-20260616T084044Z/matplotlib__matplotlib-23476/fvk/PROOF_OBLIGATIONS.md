# Proof Obligations

Status: constructed, not machine-checked.

## O1: High-DPI Serialization Normalizes Runtime DPI

Given `L > 0`, `R > 1`, and live high-DPI figure state
`fig(L * R, L, R, L * R)`, `getState` must produce
`pickle(L, L, L * R)`.

Source trace: `Figure.__getstate__` checks `self.canvas.device_pixel_ratio != 1`
and assigns `state["_dpi"] = state.get('_original_dpi', state["_dpi"])`.

Finding trace: F1.

## O2: Ratio-1 Serialization Preserves Current DPI

Given ratio-1 state `fig(D, O, 1, T)`, `getState` must produce
`pickle(D, O, T)`.

Source trace: the V1 guard prevents unconditional use of `_original_dpi`.

Finding trace: F2.

## O3: Unpickle Resynchronizes DPI Transform

Given raw pickle state `pickle(P, O, T)`, `setState` must produce
`fig(P, P, 1, P)` after `Figure.__setstate__` and `FigureCanvasBase(self)`.

Source trace: V1 calls `self.dpi_scale_trans.clear().scale(self._dpi)` before
`FigureCanvasBase(self)`, and `FigureCanvasBase` sets `_original_dpi` from
current figure DPI.

Finding trace: F3.

## O4: Same-Ratio High-DPI Roundtrip Is Idempotent

Given initial high-DPI state `fig(L * R, L, R, L * R)`, roundtripping with load
ratio `R` must produce `fig(L * R, L, R, L * R)`, not
`fig(L * R * R, L * R, R, L * R * R)`.

Source trace: O1 stores `L`; O3 restores base DPI `L`; backend attachment uses
`R * _original_dpi`.

Finding trace: F1.

## O5: Ratio-1 Roundtrip Preserves Current DPI

Given initial ratio-1 state `fig(D, O, 1, T)`, roundtripping with load ratio `1`
must produce `fig(D, D, 1, D)`.

Source trace: O2 stores `D`; O3 restores and resets base canvas original to
`D`.

Finding trace: F2.

## O6: Compatibility Obligation

The patch must not change public method signatures, pickle state type, backend
manager restoration path, or canvas API dispatch.

Source trace: diff only changes internal state normalization and transform
resync in `Figure.__getstate__` and `Figure.__setstate__`.

Finding trace: F4.

## O7: Honesty and Scope Obligation

The FVK proof is constructed only. Machine-checking commands are emitted but
not run. The mini-K model uses positive integer scalars for DPI/ratio; a richer
numeric model is needed for a machine-checked proof over non-integer ratios.

Finding trace: F5.
