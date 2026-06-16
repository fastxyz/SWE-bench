# Iteration Guidance

Status: V2 source changes are justified by the FVK findings and proof
obligations. No further source change is recommended in the audited scope.

## What changed from V1 to V2

V1 preserved all tick visibility keys across every `Axes.clear()`. That fixed
the reproduced shared-subplot symptom but violated the rcParam-on-clear
obligation when rcParams changed after axes creation.

V2 narrows the preservation:

- normal axes get current rcParam tick side defaults on every clear;
- subplot axes that previously ran `label_outer` rerun that helper after clear;
- twinned axes preserve structural tick side placement.

## Next checks for a normal development environment

The following commands are intentionally not run in this benchmark session:

```sh
kompile fvk/mini-mpl-clear.k --backend haskell
kast --backend haskell fvk/axes-clear-spec.k
kprove fvk/axes-clear-spec.k
```

Suggested tests, if test editing and execution are available later:

- Reproduce the issue example and assert inner x/y tick labels are hidden after
  each axes is cleared and replotted.
- Use an rc context that changes `xtick.top` or `ytick.right` after axes
  creation, then call `clear()` and assert the cleared axes follows the current
  rcParams.
- Clear a `twinx()` and `twiny()` axes and assert the independent axis stays on
  the opposite side.

## Residual risk

The proof is constructed over a small model of tick visibility state, not over a
full Python or full Matplotlib semantics. The artifacts are therefore useful as
an audit and proof plan, but final proof confidence requires running the emitted
K commands in a real K environment and running Matplotlib's test suite in a real
Python environment.
