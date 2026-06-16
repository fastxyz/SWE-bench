# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or test commands were run.

## Machine-Check Commands To Run Later

```sh
kompile fvk/mini-python-figure-pickle.k --backend haskell
kast --backend haskell fvk/figure-pickle-spec.k
kprove fvk/figure-pickle-spec.k
```

Expected machine-check result after any syntax adjustments required by the
local K version: `#Top` for all claims.

## Trusted Base

- The mini-K semantics in `fvk/mini-python-figure-pickle.k` faithfully abstracts
  the DPI-relevant state transitions of `Figure.__getstate__`,
  `Figure.__setstate__`, `FigureCanvasBase(self)`, and backend device-ratio
  attachment.
- The model uses exact positive integer scalars for DPI and ratio.
- Partial correctness only; no termination proof is needed for the changed
  no-loop methods.

## Claim Proofs

### `GETSTATE-HIDPI-LOGICAL`

Initial state:

```text
fig(L * R, L, R, L * R), with L > 0 and R > 1
```

Symbolic execution:

1. The `getState` high-DPI rule applies because `R =/= 1`.
2. The rule rewrites stored DPI to `O`, instantiated as `L`.
3. Result:

```text
pickle(L, L, L * R)
```

This discharges O1.

### `GETSTATE-RATIO-ONE-PRESERVES-CURRENT-DPI`

Initial state:

```text
fig(D, O, 1, T), with D > 0
```

Symbolic execution:

1. The ratio-1 `getState` rule applies.
2. The rule stores current `D`, not `O`.
3. Result:

```text
pickle(D, O, T)
```

This discharges O2 and the ordinary-DPI frame condition.

### `SETSTATE-RESYNCS-DPI-TRANSFORM`

Initial pickle state:

```text
pickle(P, O, T), with P > 0
```

Symbolic execution:

1. The `setState` rule applies.
2. Restored live DPI becomes `P`.
3. The transform scale becomes `P`, modeling V1's
   `dpi_scale_trans.clear().scale(self._dpi)`.
4. The base canvas treats `P` as the new original DPI.
5. Result:

```text
fig(P, P, 1, P)
```

This discharges O3.

### `ROUNDTRIP-HIDPI-SAME-RATIO-IDEMPOTENT`

Initial state:

```text
fig(L * R, L, R, L * R), with L > 0 and R > 1
```

Composition by transitivity:

1. By `GETSTATE-HIDPI-LOGICAL`, serialization stores `pickle(L, L, L * R)`.
2. By `SETSTATE-RESYNCS-DPI-TRANSFORM`, unpickle/base-canvas state is
   `fig(L, L, 1, L)`.
3. Backend attachment with ratio `R` rewrites to `fig(L * R, L, R, L * R)`.

The final live DPI equals the starting live DPI `L * R`. The legacy failing
state `fig(L * R * R, L * R, R, L * R * R)` is unreachable in this model
because the stored DPI is `L`, not `L * R`.

This discharges O4.

### `ROUNDTRIP-RATIO-ONE-PRESERVES-DPI`

Initial state:

```text
fig(D, O, 1, T), with D > 0
```

Composition:

1. Ratio-1 serialization stores `pickle(D, O, T)`.
2. Unpickle/base-canvas state becomes `fig(D, D, 1, D)`.
3. Ratio-1 backend attachment leaves `fig(D, D, 1, D)`.

This discharges O5.

### `ROUNDTRIP-HIDPI-LOAD-RATIO-ONE-USES-LOGICAL-DPI`

Initial state:

```text
fig(L * R, L, R, L * R), with L > 0 and R > 1
```

Composition:

1. Serialization stores logical `pickle(L, L, L * R)`.
2. Unpickle/base-canvas state becomes `fig(L, L, 1, L)`.
3. Ratio-1 backend attachment leaves `fig(L, L, 1, L)`.

This proves that a high-DPI pickle loaded without a high-DPI backend uses
logical DPI, which is the backend-neutral counterpart of the same normalization
rule.

## Adequacy and Completeness Check

The claims cover the full public intent space relevant to the issue:

- high-DPI repeated same-backend load;
- ratio-1 ordinary pickle behavior;
- transform consistency after load;
- backend-neutral placement in shared figure serialization code.

The claims do not cover arbitrary non-integer display ratios in a
machine-checkable numeric theory. This is recorded as F5 and does not justify a
source edit.

## Test Recommendation

No test files were read or edited as part of this FVK pass. If public tests
exist for in-domain high-DPI roundtrip idempotence, they would be subsumed only
after the emitted K commands are machine-checked and return `#Top`. Keep all
tests until then.
