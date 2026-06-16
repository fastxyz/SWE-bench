# FVK Proof

Status: constructed, not machine-checked. The commands in this file were not
executed.

## What Is Proved

For every finite Python built-in dict, set, and frozenset in the modeled domain,
`srepr` dispatches to an explicit `ReprPrinter` method and recursively renders
contained objects with the repr printer rather than normal `str` formatting.
The output shape remains executable Python container syntax.

## Formal Core

K artifacts:

- `fvk/mini-srepr.k`
- `fvk/srepr-container-spec.k`

Claims:

- C-DICT: `srepr(dict(PS)) => dictText(sreprPairs(sortPairs(PS)))`
- C-SET-EMPTY: `srepr(set(.Objs)) => emptySetText()`
- C-SET-NONEMPTY: `srepr(set(OS)) => setText(sreprObjs(sortObjs(OS)))`
- C-FROZENSET-EMPTY: `srepr(frozenset(.Objs)) => frozensetText(emptySetText())`
- C-FROZENSET-NONEMPTY:
  `srepr(frozenset(OS)) => frozensetText(setText(sreprObjs(sortObjs(OS))))`

`sortPairs` and `sortObjs` model SymPy's `default_sort_key` ordering. `atomSrepr`
and `atomStr` are distinct observable text constructors, so the model can
distinguish the intended fix from the legacy fallback.

## Constructed Proof Sketch

There are no recursive program calls and no unbounded source loop circularity in
the V1 methods under audit. The finite source traversals over materialized
sorted keys/elements are modeled as structural helper functions over `Pairs` and
`Objs`. The proof is by symbolic execution of the relevant dispatch target plus
structural simplification of those helpers.

For C-DICT, the left side `srepr(dict(PS))` rewrites by the `sreprObj(dict(PS))`
rule in `mini-srepr.k` to `dictText(sreprPairs(sortPairs(PS)))`. The
`hasNoDuplicateKeys(PS)` side condition states the normal dict well-formedness
condition for the pair-list model. Each `pair(K, V)` in the sorted pair list is
then rewritten by `sreprPairs` to `pairText(sreprObj(K), sreprObj(V))`, which is
the formal version of V1's `self._print(key)` and `self._print(expr[key])`.

For C-SET-EMPTY, `srepr(set(.Objs))` rewrites to `emptySetText()`, corresponding
to concrete `set()`. This discharges the Python syntax corner case where `{}` is
a dict literal.

For C-SET-NONEMPTY, the non-empty side condition allows the non-empty set rule;
symbolic execution rewrites to `setText(sreprObjs(sortObjs(OS)))`. Each element
is then recursively rewritten by `sreprObjs`, matching V1's `reprify` call over
the `default_sort_key`-sorted elements.

For C-FROZENSET-EMPTY and C-FROZENSET-NONEMPTY, the same set reasoning is wrapped
by `frozensetText(...)`, matching V1's `frozenset()` and `frozenset(<set text>)`
templates.

By Transitivity, these symbolic rewrites establish the target postconditions.
The frame conditions follow from source inspection: public signatures are
unchanged; no `_print_Dict` is added; list and tuple methods are unchanged.

## Adequacy Gate

The formal English in `fvk/SPEC.md` matches the public intent:

- The prompt's wrong outputs `{x, y}` and `{x: y}` are not preserved.
- The prompt's correct list/tuple behavior is generalized to dict/set member
  rendering.
- The docs' executable-output requirement is preserved by Python literal or
  constructor syntax.
- The only extra family member, `frozenset`, is justified by the same built-in
  unordered-container mechanism and sibling printers.

No required behavior is marked fail or ambiguous. Therefore the proof, if
machine-checked, would justify keeping V1 unchanged.

## Commands To Machine-Check Later

These are the exact commands that should be run in an environment with K
available:

```sh
kompile fvk/mini-srepr.k --backend haskell
kast --backend haskell fvk/srepr-container-spec.k
kprove fvk/srepr-container-spec.k
```

Expected `kprove` outcome: `#Top`.

## Residual Risk

The proof is constructed, not machine-checked. It relies on the adequacy of the
mini semantics for this focused printer behavior, the correctness of the
`default_sort_key` abstraction, and the standard Python equality/evaluable-syntax
contract for dict, set, and frozenset.

Termination was not separately proved. The modeled domain is finite built-in
containers, and the source traversals are over finite `keys()`/sorted element
lists.

## Test Redundancy Recommendation

No tests were edited. Any future unit tests that assert only the in-domain
examples covered here, such as `srepr({x, y})` and `srepr({x: y})`, would be
subsumed only after the K commands above are actually machine-checked. Until
then, keep all tests.
