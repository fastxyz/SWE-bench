# Public Compatibility Audit

Status: source audit only; no code or tests executed.

## Changed Public Symbol

- `matplotlib.axes.Axes.hexbin`
  - Signature: unchanged.
  - Return type: unchanged (`PolyCollection`).
  - Keyword forwarding: unchanged; all unrelated kwargs still flow to
    `PolyCollection`.
  - Behavioral change: `C` mode with explicit `mincnt` now uses an inclusive
    threshold.
  - Compatibility status: intended behavior change per issue.

## Public Wrapper

- `matplotlib.pyplot.hexbin`
  - `mincnt` remains in the wrapper signature and is forwarded to
    `Axes.hexbin` unchanged.
  - No wrapper edit is required because the wrapper copies documentation from
    `Axes.hexbin` and delegates the call.

## Overrides and Call Sites

- Source search found no second `Axes.hexbin` implementation in `repo/lib`.
- Existing public tests exercise `hexbin` extent, empty input, pickability,
  log scaling, linear rendering, and clim behavior. None assert `mincnt`
  behavior, and none require the strict `C`-mode threshold.

## Verdict

No public API, dispatch, signature, or producer/consumer compatibility issue was
introduced by V1.
