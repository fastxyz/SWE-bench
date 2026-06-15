# FVK Iteration Guidance

## Decision

V1 stands. The FVK audit found no source-code defect requiring a V2 edit.

## Why No Source Edit Is Needed

F1/PO1 identifies the original regression: lazy URL kwargs reached
`get_context_data()`. V1 fixes this by moving the wrapper pass after the
`get_context_data(**kwargs)` call.

F2/PO2/PO4 requires the deprecation behavior to remain for unchanged URL kwargs
that are still exposed in the final context. V1 preserves that by wrapping the
final context after user code runs.

F3/PO3 requires the post-processing step not to reinsert removed kwargs or
overwrite replacements. V1's membership and identity check satisfies that
obligation.

F4/PO5 requires public override compatibility. V1 does not alter public method
signatures or virtual-dispatch argument shape.

F5/PO6 rejects ORM adaptation as the wrong layer for this issue.

## Follow-Up Tests To Add In A Normal Development Environment

Do not edit tests in this benchmark task. In normal development, add a focused
test with a `TemplateView` override that records `type(kwargs["offer_slug"])`
and filters or compares it as a plain slug. Keep the existing deprecation test
for final context access.

## Machine-Checking Follow-Up

The proof artifacts are constructed only. If K is available later, run:

```sh
kompile fvk/mini-templateview.k --backend haskell
kast --backend haskell fvk/templateview-spec.k
kprove fvk/templateview-spec.k
```

Until those commands return `#Top`, do not remove any tests based on FVK.
