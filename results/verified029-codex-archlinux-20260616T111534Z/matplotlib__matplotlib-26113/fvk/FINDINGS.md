# Findings

Status: FVK audit findings, constructed without executing tests or code.

## FVK-F1: Strict `C`-Mode Comparator Was the Root Bug

- Classification: code bug, resolved by V1.
- Evidence: `benchmark/PROBLEM.md` reports that `C` mode with `mincnt=1`
  displayed only bins with at least two data points.
- Concrete case: a bin with `count=1`, `C` supplied, and `mincnt=1`.
- Pre-V1 observed by source reasoning: `len(acc) > mincnt` is `1 > 1`, so the
  bin is hidden.
- Expected: `1 >= 1`, so the bin is displayed, matching count-only mode.
- Proof obligation: `PO-2`.
- V1 status: fixed by `len(acc) >= mincnt`.

## FVK-F2: Omitted `mincnt` in `C` Mode Must Remain Non-Empty Only

- Classification: intended default behavior, confirmed by V1.
- Evidence: the issue says the default is understandable because reducers may
  not yield sensible output for empty arrays.
- Concrete case: a bin with `count=0`, `C` supplied, and `mincnt=None`.
- Expected: bin is not reduced or displayed by the threshold path.
- Proof obligation: `PO-3`.
- V1 status: confirmed by setting the internal `C`-mode default threshold to
  `1` before applying the inclusive comparator.

## FVK-F3: Explicit `mincnt=0` With `C` Is Edge-Specified

- Classification: underspecified edge behavior, non-blocking.
- Evidence: the issue includes `mincnt=0` in reproduction and requests
  `len(vals) >= mincnt`, but the public docstring describes `mincnt` as
  `int > 0`.
- Concrete case: a bin with `count=0`, `C` supplied, `mincnt=0`, and
  `reduce_C_function=np.sum`.
- Expected under the requested comparator and a reducer defined on empty input:
  the bin is eligible because `0 >= 0`.
- Residual condition: arbitrary reducers may fail or return NaN for empty input;
  the existing final NaN filter may still hide NaN results.
- Proof obligations: `PO-5`, with documented-domain coverage in `PO-2`.
- V1 status: acceptable. V1 does not clamp explicit zero to one; it follows the
  inclusive comparator and leaves reducer definedness to the caller for this
  out-of-documented-domain edge.

## FVK-F4: Full Rendering Is Framed, Not Formally Verified

- Classification: proof coverage boundary.
- Evidence: V1 changes only the `mincnt` docstring and the `C`-mode
  threshold/default lines.
- Concrete case: colormap normalization or marginal bar rendering.
- Expected: unchanged by V1.
- Proof obligations: `PO-6`, `PO-7`.
- V1 status: no source change needed; public compatibility audit found no
  changed API or wrapper issue.

## FVK-F5: Missing Public Regression Tests for `mincnt`

- Classification: test gap.
- Evidence: public `test_axes.py` contains `hexbin` tests for extent, empty
  input, pickability, log rendering, linear rendering, and clim, but no `mincnt`
  threshold assertion.
- Recommended tests: compare selected offsets for `C=None` and `C` supplied
  with `mincnt=1`, and assert omitted `mincnt` in `C` mode does not include
  empty bins.
- V1 status: no test edits allowed by task; hidden tests are not used as
  evidence.
