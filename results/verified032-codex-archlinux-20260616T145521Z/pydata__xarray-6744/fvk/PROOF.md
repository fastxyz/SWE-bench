# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## What Is Proved

For every yielded one-dimensional rolling position with `N >= 0`, `W > 0`, and
`0 <= I < N`, V1 computes iterator slice bounds that match the intended rolling
alignment:

- `center=False`: right-aligned bounds.
- `center=True`: centered bounds matching `Variable.rolling_window`.

This is partial correctness of the bound calculation and its immediate iterator
frame conditions. Termination is not separately proved; the iterator loops over
a finite `zip(self.window_labels, starts, stops)` sequence.

## K Proof Core

Formal files:

- `mini-python-rolling.k`
- `rolling-iter-spec.k`

The first claim rewrites `rollingBounds(N,W,false,I)` to right-aligned bounds.
The second claim rewrites `rollingBounds(N,W,true,I)` to centered bounds. Three
concrete claims instantiate the public issue witness at `N=9`, `W=3`, and
positions `I=0`, `I=1`, and `I=8`.

The exact commands to machine-check later are:

```sh
cd fvk
kompile mini-python-rolling.k --backend haskell
kast --backend haskell rolling-iter-spec.k
kprove rolling-iter-spec.k
```

Expected result after machine-checking: `#Top`.

## Arithmetic Argument

Let `I` be the zero-based output position and `W > 0`.

For `center=False`, V1 sets `offset=0`, `stop0=I+1`, and
`start0=I+1-W`. Therefore:

- `start = max(I - (W - 1), 0)`
- `stop = min(I + 1, N)`

which is the documented right-aligned rolling window.

For `center=True`, `Variable.rolling_window` uses:

- left padding `L = W // 2`
- right padding `R = W - 1 - L`

For positive integer `W`, `R = (W - 1) // 2`.

V1 sets `offset=R`, `stop0=I+1+R`, and `start0=stop0-W`. The stop expression is
already `I + R + 1`. For the start expression:

- If `W = 2q`, then `R = q - 1`, so
  `start0 = I + 1 + (q - 1) - 2q = I - q = I - (W // 2)`.
- If `W = 2q + 1`, then `R = q`, so
  `start0 = I + 1 + q - (2q + 1) = I - q = I - (W // 2)`.

After V1 clips `start0` with `max(..., 0)` and `stop0` with `min(..., N)`, the
final bounds are exactly the centered construction bounds in PO-3.

## Issue Witness

For the issue's `N=9`, `W=3`, `center=True`:

- `I=0`: `start=0`, `stop=2`, so only two values are present and default
  `min_periods=3` masks the manual mean to `nan`.
- `I=1`: `start=0`, `stop=3`, so the manual mean is `2`.
- `I=8`: `start=7`, `stop=9`, so only two values are present and default
  `min_periods=3` masks the manual mean to `nan`.

The same arithmetic gives interior means `3` through `8`, matching the expected
centered reduction sequence.

## Frame Conditions

Labels are unchanged because V1 still iterates over `self.window_labels`.

Window construction is unchanged except for bounds: V1 still calls
`self.obj.isel({dim0: slice(start, stop)})`.

`min_periods` behavior is unchanged after the corrected slice is selected: V1
still computes `window.count(dim=dim0)` and applies
`window.where(counts >= self.min_periods)`.

The multidimensional guard is unchanged: `self.ndim > 1` still raises
`ValueError`.

## Findings and Verdict

FI-1 identifies the original bug. FI-2 through FI-5 confirm that V1 discharges
the centered issue witness, even-window centering, edge clipping, masking, and
public compatibility obligations. FI-6 records the honesty gate.

Verdict: V1 stands unchanged. No additional source edit is justified by the FVK
obligations.

## Test Guidance

No tests were modified. After machine-checking, tests that only restate
right-aligned in-domain iterator bounds may be considered proof-subsumed, but
removal is conditional on `kprove` returning `#Top` and is outside this task.
The useful future public tests are centered manual iteration for an odd window
and an even window, because those directly cover FI-2 and FI-3.
