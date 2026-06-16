# FVK Spec: `sympy.utilities.iterables.partitions`

Status: constructed, not machine-checked. No tests, Python code, or K tooling were run.

## Scope

This FVK pass audits the V1 repair for GitHub issue `sympy__sympy-20154`: `partitions()` reused one mutable output dictionary across yields. The verified behavioral slice is the public yield boundary: every yielded partition dictionary must be a stable snapshot of the internal partition state at that yield.

The full integer-partition enumeration algorithm is treated as an unchanged frame condition. V1 does not alter the algorithm that mutates `ms`, `keys`, `room`, or the `m`/`k` filtering decisions; it only changes whether the public output aliases that internal state.

## Public Intent Ledger

| Evidence | Source | Semantic obligation |
|---|---|---|
| E-001 | issue: "`partitions()` iterator ... reuses the output dictionaries" | Fix dictionary object reuse at the yield boundary. |
| E-002 | issue: "copy the dictionary before yielding it" | A shallow `dict.copy()` snapshot is an intended repair. |
| E-003 | issue: "`list(partitions())` will give an apparently wrong result" | Retained outputs must keep their yield-time contents. |
| E-004 | issue: "subtle bugs ... used in a nontrivial way" | Caller mutation of one yielded dict must not affect generator state or other yielded dicts. |
| E-005 | docstring: partition represented as a dictionary | Preserve dictionary return type and dictionary contents. |
| E-006 | docstring: `size=True` returns `(M, P)` | Preserve size tuple shape and snapshot `P`. |
| E-007 | public tests compare copied partition dicts | Preserve value equality and yield order of partition maps. |
| E-008 | public callsites consume `p.items()`/`sorted(p)` | Preserve dictionary API for internal and public consumers. |

`fvk/PUBLIC_EVIDENCE_LEDGER.md` contains the full ledger. The previous docstring warning and tests that required caller-side `.copy()` are SUSPECT legacy evidence for aliasing, because the issue itself identifies that behavior as the defect.

## Contract

For each execution of `partitions(n, m, k, size=False)` that yields a sequence of internal partition maps `S0, S1, ..., Sj`:

- The public output sequence is a sequence of dictionaries `D0, D1, ..., Dj`.
- For every `i`, `Di == Si` by dictionary extensional equality at the moment of yield.
- For every `i`, `Di` is not the mutable internal working dictionary used for later generator steps.
- For every `i != h`, `Di is not Dh`.
- Later internal mutations must not change any earlier `Di`.
- Mutating a yielded `Di` must not change the generator's internal state or any other yielded dictionary.

For `size=True`, each public output is `(Mi, Di)`:

- `Di` satisfies the same snapshot and freshness obligations.
- `Mi == sum(Di.values())`, matching the documented size component.
- Tuple shape and dictionary mutability are preserved.

Boundary cases that yield only one dictionary, such as the empty/impossible partition convention, are compatible with the contract: the yielded literal dictionary is fresh for that call and no later generator mutation occurs.

## Formalization

The K artifacts are:

- `fvk/mini-python-partitions.k`: a minimal heap/object-id model of the yield boundary. `emit(M)` models `yield M.copy()` by allocating a fresh object id and storing the map contents at that id.
- `fvk/partitions-snapshot-spec.k`: two claims, `collect(STATES)` and `collectSize(STATES)`, proving that collecting an abstract sequence of partition maps yields fresh ids whose heap contents match the source maps.

The exact commands to machine-check later are:

```sh
cd fvk
kompile mini-python-partitions.k --backend haskell
kast --backend haskell partitions-snapshot-spec.k
kprove partitions-snapshot-spec.k
```

Expected result if the constructed claims and mini semantics are accepted by K: `#Top` for both claims. These commands were not run.

## Adequacy

The adequacy round trip is recorded in:

- `fvk/INTENT_SPEC.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

Verdict: adequate for the aliasing/snapshot repair. The spec does not overclaim full enumeration correctness or total correctness.
