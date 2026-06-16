# Public Evidence Ledger

Status: public-intent evidence only; no hidden tests or external sources used.

## E1: Reported Defect

- Source: `benchmark/PROBLEM.md`
- Evidence: "Different behavior of `hexbin`s `mincnt` parameter, depending on
  whether the `C` parameter is supplied."
- Obligation: the `mincnt` threshold should not become stricter merely because
  `C` is supplied.
- Status: encoded in `CLAIM-C-EXPLICIT` and `PO-2`.

## E2: Inclusive Count-Only Baseline

- Source: `benchmark/PROBLEM.md`
- Evidence: "`mincnt` value of `1` works as I intuitively expect: it plots only
  gridpoints that have at least 1 datum."
- Obligation: explicit `mincnt=1` keeps bins with count exactly one.
- Status: encoded in `CLAIM-COUNT-EXPLICIT` and `CLAIM-C-EXPLICIT`.

## E3: Expected Cross-Mode Equality

- Source: `benchmark/PROBLEM.md`
- Evidence: "with `mincnt == 1` I'd expect the same gridpoints to be plotted,
  whether `C` is supplied or not"
- Obligation: for the same bin counts, explicit positive `mincnt` yields the
  same visible-bin predicate in count mode and `C` mode.
- Status: encoded in `PO-2` and proved by threshold equality.

## E4: Requested Comparator

- Source: `benchmark/PROBLEM.md`
- Evidence: "len(vals) >= mincnt, rather than the current len(vals) > mincnt"
- Obligation: the `C` path must use an inclusive comparator for explicit
  `mincnt`.
- Status: encoded in `CLAIM-C-EXPLICIT`; V1 source uses `len(acc) >= mincnt`.

## E5: Omitted `mincnt` With `C`

- Source: `benchmark/PROBLEM.md`
- Evidence: "With `C` specified but not `mincnt` specified, I can kind of
  understand why it defaults to only gridpoints that have at least one data
  point, as otherwise the `reduce_C_function` has to yield a sensible output
  for an empty array."
- Obligation: `C` mode with `mincnt=None` uses an effective threshold of one,
  not zero.
- Status: encoded in `CLAIM-C-DEFAULT` and `PO-3`.

## E6: Omitted `mincnt` Without `C`

- Source: `benchmark/PROBLEM.md`
- Evidence: "no mincnt specified, no C argument ... all gridpoints are shown,
  even when the values are zero"
- Obligation: count mode with `mincnt=None` keeps all bins, including zero-count
  bins.
- Status: encoded in `CLAIM-COUNT-DEFAULT` and `PO-4`.

## E7: Public Docstring Contract

- Source: `repo/lib/matplotlib/axes/_axes.py`
- Evidence: `C` values are reduced per hexagon using `reduce_C_function`; after
  V1, `mincnt` says "at least".
- Obligation: filtering decides which bins are present, while reduction decides
  the values for present `C` bins.
- Status: reflected in the selected-bin projection and reducer frame condition.

## E8: Public Compatibility Surface

- Source: `repo/lib/matplotlib/axes/_axes.py` and
  `repo/lib/matplotlib/pyplot.py`
- Evidence: `Axes.hexbin` accepts `mincnt=None`; `pyplot.hexbin` forwards
  `mincnt` unchanged.
- Obligation: preserve signatures and call forwarding.
- Status: encoded in `PUBLIC_COMPATIBILITY_AUDIT.md` and `PO-6`.
