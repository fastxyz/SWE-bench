# FVK Spec

Status: constructed, not machine-checked.

## Scope

The verified unit is the old assumptions closure used by
`Symbol(...).is_finite`, specifically the path from constructor assumptions into
`StdFactKB` and `_assume_rules`.

The observable under verification is whether `finite=True` appears in the
closed fact set for a symbol. The model intentionally excludes unrelated
assumption facts except where needed to prove or frame this observable.

## Contract

For old assumptions:

- `rational=True` implies `finite=True`.
- `integer=True` implies `finite=True`.
- `even=True` implies `finite=True`.
- `odd=True` implies `finite=True` through the same existing parity/integer path.
- `real=True` alone is not changed by this fix.
- no relevant numeric-set assumption leaves finiteness unknown.

## Public Intent Ledger

See `PUBLIC_EVIDENCE_LEDGER.md`. The critical entries are:

- E-1/E-2: the issue requires `even=True` to imply finite.
- E-3: the issue requires `integer=True` to imply finite.
- E-4: the public hint identifies `rational -> finite` as the safe implication.
- E-5: the public hint rejects broadening old `real` to finite in this issue.

## Formal Artifacts

- `mini-assumptions.k`: small K semantics for the relevant assumption closure.
- `assumptions-spec.k`: reachability claims for rational, integer, even, real
  frame behavior, and the generic no-facts frame.

Exact commands to machine-check later, not run in this session:

```sh
kompile fvk/mini-assumptions.k --backend haskell
kast --backend haskell fvk/assumptions-spec.k
kprove fvk/assumptions-spec.k
```

Expected result if the mini semantics and claims are accepted by K: `#Top`.
