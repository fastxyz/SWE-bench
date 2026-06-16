# ITERATION GUIDANCE

Status: V1 stands unchanged.

## Decision

No V2 source edit is justified by the FVK audit. V1 satisfies the intent-derived
spec and all proof obligations:

- F2/PO2: the span rectangle no longer uses `add_patch`, so it does not update
  data limits.
- F2/PO3: interactive handles no longer use `axvline`/`axhline` or `add_line`,
  so they do not update data limits or request autoscale.
- F3/PO4: rectangle and handle geometry are preserved.
- F4/PO6: no public signature or test-file change is needed.

## Suggested Future Tests

These are recommendations only; the task forbids editing tests here.

1. Construct `SpanSelector(ax, callback, "horizontal", interactive=True)` after
   plotting x data away from zero, then assert the x limits remain based on the
   plotted data.
2. Repeat for `direction="vertical"` and y data away from zero.
3. Assert `ToolLineHandles.positions`, `set_visible`, and `set_animated`
   behavior remain unchanged after direct `Line2D` construction.

## Machine-Check Follow-Up

In an environment with K installed, run:

```sh
kompile fvk/mini-matplotlib-widgets.k --backend haskell
kast --backend haskell fvk/span-selector-spec.k
kprove fvk/span-selector-spec.k
```

Until those commands return `#Top`, treat the proof as constructed rather than
machine-checked and keep all tests.
