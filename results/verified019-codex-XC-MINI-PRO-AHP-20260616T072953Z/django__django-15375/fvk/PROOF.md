# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, or `kprove` command was run.

## Claims

The proof targets the claims in `aggregate-default-spec.k`:

- `TERMINAL-DEFAULT-AFTER-ANNOTATE-VALID`
- `NONTERMINAL-DEFAULT-NOT-SUMMARY`
- `TERMINAL-NO-DEFAULT-VALID`
- `PREFIX-REGRESSION-SHAPE`

There are no loop circularities in this audited slice.

## Proof Sketch

### Terminal defaulted aggregate after annotation

Start with `plan(true, resolve(true, terminal))`.

1. `isTerminal(terminal)` rewrites to `true`.
2. `resolve(true, terminal)` rewrites to `coalesce(agg(true), true)`.
3. `isSummary(coalesce(agg(true), true))` rewrites to `true`.
4. The `plan(true, E) => valid requires isSummary(E)` rule applies.
5. The final outcome is `valid`.

This discharges PO1 and PO2 for the reported issue path.

### Non-terminal defaulted aggregate annotation

Start with `isSummary(resolve(true, nonTerminal))`.

1. `isTerminal(nonTerminal)` rewrites to `false`.
2. `resolve(true, nonTerminal)` rewrites to `coalesce(agg(false), false)`.
3. `isSummary(coalesce(agg(false), false))` rewrites to `false`.
4. The final outcome is `false`.

This discharges PO3 and justifies keeping V1's inherited summary flag instead of assigning `True` unconditionally.

### Non-default terminal aggregate frame condition

Start with `plan(true, resolve(false, terminal))`.

1. `resolve(false, terminal)` rewrites to `agg(true)`.
2. `isSummary(agg(true))` rewrites to `true`.
3. The subquery planning rule for summary expressions applies.
4. The final outcome is `valid`.

This preserves the public control example where `annotate()` followed by aggregate without `default` already worked.

### Pre-fix regression witness

Start with `plan(true, resolveBefore(true, terminal))`.

1. `resolveBefore(true, terminal)` rewrites to `coalesce(agg(true), false)`.
2. `isSummary(coalesce(agg(true), false))` rewrites to `false`.
3. The subquery planning rule for non-summary expressions applies.
4. The final outcome is `invalid`.

This localizes the reported empty outer `SELECT` to loss of the summary flag on the internal `Coalesce` wrapper.

## Machine-check Commands

These commands are emitted for a later environment. They were not run here.

```sh
cd fvk
kompile mini-django-aggregate.k --backend haskell
kast --backend haskell aggregate-default-spec.k
kprove aggregate-default-spec.k
```

Expected machine-check result if the fragment parses and the constructed proof is accepted: `#Top`.

## Residual Risk

The proof is partial and model-level. It does not prove Django's full SQL compiler, backend SQL parsing, database execution, aggregate numeric correctness, or query performance. The model is adequate for the issue because the failing and fixed paths differ on the modeled discriminator: whether the wrapper is summary when `get_aggregation()` decides outer-query reduction.

## Test Recommendation

No tests were read, modified, removed, or run. If a later machine check returns `#Top`, focused tests that assert the in-domain planning behavior of defaulted terminal aggregates after annotation would be subsumed by this model-level proof. Integration/backend tests should still be kept because the proof does not cover backend SQL execution.
