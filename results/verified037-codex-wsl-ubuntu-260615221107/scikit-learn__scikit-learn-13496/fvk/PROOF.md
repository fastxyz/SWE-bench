# Constructed Proof

Status: constructed, not machine-checked.

## What is proved

Against the API-level mini semantics in `mini-iforest-api.k`, the claims in
`iforest-warm-start-spec.k` prove partial correctness of the constructor state
transition relevant to the issue:

1. Construction without `warm_start` reaches a state with `warm_start=false`.
2. Construction with explicit boolean `W` reaches a state with `warm_start=W`.
3. Old positional arguments through `verbose` keep their old field mapping.

There are no loops or recursive calls in the modeled path, so no circularity is
required.

## Proof sketch

### `IFOREST-DEFAULT-WARM-START`

Initial configuration:

```k
<k> oldCtor(NE, MS, C, MF, B, NJ, BH, RS, V) </k>
<state> .Map </state>
```

The `oldCtor` rewrite rule fires once and produces:

```k
<k> .K </k>
<state> iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, false) </state>
```

The `iforestState` function expands to a map containing
`kWarmStart |-> false` and preserving all old fields. This matches the claim.

### `IFOREST-EXPLICIT-WARM-START`

Initial configuration:

```k
<k> newCtor(NE, MS, C, MF, B, NJ, BH, RS, V, W) </k>
<state> .Map </state>
```

The `newCtor` rewrite rule fires once and produces:

```k
<k> .K </k>
<state> iforestState(NE, MS, C, MF, B, NJ, BH, RS, V, W) </state>
```

The resulting map stores `kWarmStart |-> W`, which is the pass-through
obligation.

### `IFOREST-POSITIONAL-COMPAT`

Initial configuration:

```k
<k> oldCtor(100, Auto, Legacy, OneFloat, false, 3, New, 0, 1) </k>
<state> .Map </state>
```

The same `oldCtor` rule reaches:

```k
<state>
  iforestState(100, Auto, Legacy, OneFloat, false, 3, New, 0, 1, false)
</state>
```

Thus the old sixth, seventh, eighth, and ninth positional arguments remain
`n_jobs`, `behaviour`, `random_state`, and `verbose` respectively. This proof
obligation failed for V1 and is satisfied by V2.

## Machine-check commands

These commands are recorded for a future environment with K installed. They
were not executed here.

```sh
kompile fvk/mini-iforest-api.k --backend haskell
kast --backend haskell fvk/iforest-warm-start-spec.k
kprove fvk/iforest-warm-start-spec.k
```

Expected machine-check result: `#Top` for all three claims.

## Test-redundancy recommendation

No tests were modified or removed. If machine-checking succeeds, unit tests that
only assert constructor parameter exposure and default/pass-through behavior are
partially subsumed by the proof, but they should be kept unless a maintainer
chooses to rely on the machine-checked K proof. Warm-start integration tests
that exercise actual fitting should remain, because the mini semantics does not
prove tree-building behavior.

## Residual risk

- The proof is constructed, not machine-checked.
- The mini semantics abstracts Python object construction to the observable
  API state relevant to this issue.
- Termination is trivial for the modeled constructor rewrite but not a proof of
  estimator fitting termination or performance.
