# Constructed Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were executed.

## Claims Proved

C1. `reprRepeated(O)` rewrites to `buildRepr(O)`, modeling
`_RepeatedSplits.__repr__` delegating to `_build_repr(self)`.

C2. A default `RepeatedKFold` object with direct attributes
`n_repeats=10`, `random_state=None`, and `cvargs["n_splits"] = 5` rewrites to
`RepeatedKFold(n_repeats=10, n_splits=5, random_state=None)`.

C3. The analogous default `RepeatedStratifiedKFold` object rewrites to
`RepeatedStratifiedKFold(n_repeats=10, n_splits=5, random_state=None)`.

C4. Direct attributes have precedence over `cvargs`.

C5. Missing direct attributes with no `cvargs` entry resolve to `None`.

## Proof Sketch

For C2 and C3, symbolic execution starts with `reprRepeated(obj(...))`.
The first semantic rule rewrites it to `buildRepr(obj(...))`. The `buildRepr`
rule then collects values for the sorted constructor-key list
`n_repeats`, `n_splits`, `random_state`.

The `resolve` function performs the key lookup. For `n_repeats` and
`random_state`, the direct-attribute rule matches first and returns `10` and
`None`. For `n_splits`, the direct-attribute list is exhausted, so `resolveCv`
matches `pair("n_splits", intVal(5))` in `cvargs` and returns `5`. The
`format` rule then produces the constructor-like string with those values.

For C4, the first `resolve` rule matches the direct pair `pair("x", noneVal)`
before consulting `cvargs`; the result is `noneVal`. For C5, both direct and
`cvargs` pairs are empty, so `resolveCv` returns `noneVal`.

There are no loops, recursion, arithmetic verification conditions, or
termination obligations in this fragment.

## Adequacy Gate

The formal English claims in `fvk/FORMAL_SPEC_ENGLISH.md` match the intent in
`fvk/INTENT_SPEC.md`. `fvk/SPEC_AUDIT.md` records each claim as pass. The only
notable intent issue is parameter order: the issue sample uses constructor
order, while the public helper/test evidence uses sorted `_pprint` order. The
spec follows the project convention because the public hint explicitly directs
the fix through `_build_repr`.

`fvk/PUBLIC_COMPATIBILITY_AUDIT.md` has no unhandled public callsite, signature,
or override issue.

## Reproduce the Machine Check Later

These commands are emitted for a future environment with K installed. They were
not run in this session.

```sh
kompile fvk/mini-python-repr.k --backend haskell
kast --backend haskell fvk/repeated-splits-repr-spec.k
kprove fvk/repeated-splits-repr-spec.k
```

Expected result after the K syntax and semantics are accepted: `kprove` returns
`#Top` for the four claims.

## Test Recommendation

Do not remove tests based on this constructed proof alone. If the K claims are
later machine-checked, focused repr regression tests for default and non-default
`RepeatedKFold` and `RepeatedStratifiedKFold` would be subsumed for the covered
repr-construction behavior. Existing broader splitter tests should remain
because this proof does not cover split generation, data validation, randomness,
or integration behavior.

