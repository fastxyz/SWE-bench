# sympy__sympy-12481 — FVK analysis

- **Verdict:** E_COSMETIC — fvk's only changes are a logically-equivalent reordering of one boolean (`if has_dups(temp): if not is_cycle:` → `if not is_cycle and has_dups(temp):`) plus an added docstring example; baseline and fvk produce identical results on every input tested, including malformed ones.
- **Pitch-worthiness (1-5):** 1 — no "passed tests but still wrong" story exists here. Baseline was already correct; fvk only tidied code and added a doctest.

> NOTE: the original investigation hint for this instance was wrong. It claimed "fvk added `raise ValueError('there were repeated elements.')` that baseline lacked" and that baseline "over-relaxed and silently accepted malformed input within a single cycle." Both claims are false — baseline keeps that exact raise, and within-cycle dups are rejected by `Cycle.__new__` independently in both variants.

## The issue
`Permutation([[0,1],[0,1]])` raised `ValueError` instead of composing the non-disjoint cycles left-to-right (returning identity). Desired: allow non-disjoint cycles ACROSS sublists, still reject genuinely invalid input.

## What baseline did
Baseline relaxed the flatten-then-`has_dups` guard in `Permutation.__new__` so the duplicate error fires only for array-form input:
```python
if has_dups(temp):
    if not is_cycle:
        raise ValueError('there were repeated elements.')
```
Cyclic input then falls through to the existing fold `c = Cycle(); for ci in args: c = c(*ci)`. `Cycle.__new__` itself rejects within-cycle repeats (`if has_dups(args): raise ValueError('All elements must be unique in a cycle.')`), so baseline still rejects malformed single cycles.

## What fvk changed and why
Two changes vs baseline:
1. Rewrote the guard as `if not is_cycle and has_dups(temp): raise ValueError('there were repeated elements.')` — fvk itself calls this "behaviorally equivalent," and it is.
2. Added a class-docstring doctest `>>> Permutation([[0, 1], [0, 1]])` → `Permutation([0, 1])`.
fvk's findings (F-3, F-4) explicitly confirm baseline already preserved array-form dup rejection and per-cycle uniqueness. fvk fixed no defect.

## Concrete demonstration
No input distinguishes baseline from fvk (verified by execution on matching-era sympy-12419 source, whose `__new__`/`Cycle` bodies are byte-identical to the patch context):

| input | baseline | fvk | expected |
|---|---|---|---|
| `Permutation([[0,1],[0,1]])` | `[0,1]` | `[0,1]` | `[0,1]` (identity) |
| `Permutation([[0,1],[0,2]])` (gold test) | `[1,2,0]` | `[1,2,0]` | `== Permutation(0,1,2)` |
| `Permutation([1,1,0])` (array dup) | raises | raises | must raise |
| `Permutation([[0,0]])` (within-cycle dup) | raises* | raises* | must raise |
| `Permutation([[1,2,1]])` (within-cycle dup) | raises* | raises* | must raise |
| `Permutation([[0,1,2],[2,3]])` | `[1,3,0,2]` | `[1,3,0,2]` | compose |

*both raise `ValueError('All elements must be unique in a cycle.')` from `Cycle.__new__`. There is no input where fvk is more correct.

## Why the tests missed it
Nothing was missed; there was no baseline defect. FAIL_TO_PASS is `test_args`. `gold_test.patch` adds exactly `assert Permutation([[0, 1], [0, 2]]) == Permutation(0, 1, 2)` and deletes a now-obsolete `raises(...)`. Both pass identically under baseline and fvk.

## Gold comparison
Gold makes the SAME semantic change as baseline, operands swapped: `if has_dups(temp) and not is_cycle: raise ValueError('there were repeated elements.')`. fvk's `if not is_cycle and has_dups(temp):` is the closest spelling to gold; baseline's nested form is logically identical to both. All three behave identically. **GOLD_MATCH: yes** (baseline already matched gold's behavior).

## Confidence & caveats
High confidence, backed by executing both variants on real Permutation/Cycle code. `a and b` vs nested `if a: if b:` over side-effect-free predicates is provably equivalent, and the doctest is non-executing. fvk's own notes are accurate and honest — they correctly state V2 is "behaviorally equivalent to V1" and claim no correctness fix.
