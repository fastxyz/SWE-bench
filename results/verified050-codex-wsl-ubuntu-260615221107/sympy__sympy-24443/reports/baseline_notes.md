# Baseline Notes

## Root cause

`_check_homomorphism()` validates a proposed homomorphism by evaluating each relator from the domain presentation under the proposed generator images. For `PermutationGroup` domains, the relators come from `domain.presentation()`, whose generators are free-group generators such as `x_0`, while the `images` dictionary is keyed by the original permutation generators.

The old `_image()` helper translated a presentation generator back to the corresponding permutation generator only when `r[i] in gens`. When a relator syllable was an inverse, `r[i]` was `x_i**-1`, so that membership test failed. The helper then tried to look up the free-group inverse directly in `images`, found nothing, and evaluated the relator incorrectly. This caused valid maps such as the identity map on `DihedralGroup(3)` to be rejected.

## Files changed

`repo/sympy/combinatorics/homomorphisms.py`

- Reused a single `presentation = domain.presentation()` result when a separate presentation is needed.
- Built a `gen_to_s` mapping from each relator generator symbol to the generator object that should be used for image lookup.
- For permutation-group domains, mapped presentation symbols to the corresponding original permutation generators by position.
- For non-permutation domains, mapped each symbol to its own free-group generator.
- Simplified `_image()` to iterate directly over `r.array_form`, using the signed exponent from each syllable. This makes inverse permutation relators evaluate as powers of the mapped permutation generator image rather than as unmapped free-group inverse elements.

## Assumptions and alternatives

I assumed that a permutation group's finite presentation generators remain positionally aligned with `domain.generators`, which was already required by the existing implementation's `gens.index(...)` lookup.

I considered mapping both `x_i` and `x_i**-1` as free-group elements. I rejected that because if a permutation group's generator list contains both a generator and its inverse as separate generators, a relator occurrence of `x_i**-1` must still evaluate as `images[g_i]**-1`, not as the independently supplied image for the separate permutation `g_i**-1`.

I did not add or edit tests, and I did not run tests or project code, per the task constraints.
