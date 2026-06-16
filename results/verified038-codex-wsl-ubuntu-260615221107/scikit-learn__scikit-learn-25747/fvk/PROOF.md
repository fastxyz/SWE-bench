# Constructed Proof

Status: constructed, not machine-checked. No K tooling was run.

## Claims Proved by Construction

The proof targets `fvk/set-output-spec.k` over the mini-semantics in
`fvk/mini-pandas-output.k`.

- PO-1: pandas auto-wrap of an existing aggregated `DataFrame` preserves the
  `DataFrame` index even when original and output row counts differ.
- PO-2: resolved feature names update existing `DataFrame` columns without
  replacing the index.
- PO-3: callable feature-name failure preserves existing `DataFrame` columns and
  index.
- PO-4: dense non-DataFrame output is converted with the supplied index.
- PO-5: sparse output reaches the sparse error state.
- PO-6: default output or disabled auto wrapping returns unchanged data.

## Proof Sketch

There are no loops and no recursive calls. Each claim is a finite symbolic
execution over one or two rewrite steps.

For PO-1, `wrapData(pandasMode, true, OBJ, ORIGINALIDX, COLS)` rewrites to
`wrapInPandas(OBJ, COLS, ORIGINALIDX)`. The object is a `df(...)` and the
column provider is modeled as raising, so the `colCallableRaises` DataFrame rule
fires. That rule returns `df(P, OLD, DFIDX)`. The supplied `ORIGINALIDX` is not
used in the right-hand side, so the mismatch side condition
`OUTROWS =/=Int INROWS` cannot produce a length-mismatch transition.

For PO-2, the input is already a `df(...)` and the column argument resolves to
`NEW`. The DataFrame `colValue` rule rewrites to `df(P, NEW, DFIDX)`. The
payload and existing index are framed unchanged.

For PO-3, the DataFrame `colCallableRaises` rule rewrites to
`df(P, OLD, DFIDX)`, framing both columns and index.

For PO-4, the input is `array(P)`. The non-DataFrame `colValue` rule rewrites to
`df(P, NEW, IDX)`, so the supplied/original index appears in the output.

For PO-5, the sparse rule is first-match by object shape and rewrites any
`sparse(P)` input to `sparseError`, preserving the production guard's intent.

For PO-6, the `defaultMode` and `pandasMode,false` rules rewrite directly to the
input object without delegating to pandas wrapping.

## Adequacy

`FORMAL_SPEC_ENGLISH.md` paraphrases the claims, and `SPEC_AUDIT.md` compares
them against `INTENT_SPEC.md`. All behavior needed to confirm V1 passes, except
direct Series wrapping, which is recorded as outside the documented domain and
not used as a premise for confirmation.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were
not run in this task.

```sh
kompile fvk/mini-pandas-output.k --backend haskell
kast --backend haskell fvk/set-output-spec.k
kprove fvk/set-output-spec.k
```

Expected machine-check result: `#Top` for all claims.

## Test Recommendation

No tests were modified. Test-removal recommendations are conditioned on a future
machine check and are not applied here.

- Keep integration tests for `FeatureUnion` and `ColumnTransformer` pandas
  output because the proof abstracts real pandas behavior.
- Add or update a helper-level test, outside this task, asserting that an
  existing `DataFrame` keeps its index while columns are updated.
- Treat any old assertion that existing `DataFrame` indexes must be overwritten
  as suspect legacy behavior under F2.

## Residual Risk

The proof is partial correctness over an abstract mini-semantics and is not
machine-checked. It does not model real pandas constructor alignment, pandas
subclasses, callable side effects beyond success/failure, or direct Series
output. Those are integration-test and future-spec concerns, not blockers for
the V1 fix against the public failure mechanism.
