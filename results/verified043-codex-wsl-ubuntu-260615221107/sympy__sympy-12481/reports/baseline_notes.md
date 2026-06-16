# Baseline Notes

## Root cause

`Permutation.__new__` flattened list-of-lists cycle input and rejected any repeated element before it built the permutation. That duplicate check made sense for array-form input, where repeated images are invalid, but it also rejected valid cyclic-form products such as `Permutation([[0, 1], [0, 1]])`. The constructor already had logic to compose list-of-lists cycles from left to right using `Cycle`, but the global duplicate rejection prevented non-disjoint cycles from reaching that path.

## Files changed

`repo/sympy/combinatorics/permutations.py`

Changed the constructor duplicate check so repeated elements still raise for array-form input, while list-of-lists cycle input is allowed to continue into the existing left-to-right `Cycle` composition loop. Also updated the constructor docstring to no longer claim that every element may appear only once in list-of-lists input.

## Assumptions and alternatives

I assumed that each individual cycle should still require unique, non-negative integer entries. That validation remains delegated to `Cycle(*ci)` when the constructor composes each cycle.

I considered replacing the constructor's list-of-lists handling with explicit `Permutation` multiplication, but rejected it because the existing `Cycle` path already implements the documented left-to-right composition and preserves singleton sizing behavior.

I also considered removing duplicate validation entirely, but rejected that because array-form permutations still must be one-to-one and should continue to reject repeated elements.
