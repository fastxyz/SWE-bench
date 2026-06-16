# Public Compatibility Audit

Status: static compatibility audit. No code was executed.

## Changed Public Symbol

`sympy.combinatorics.permutations.Permutation.__new__`

Compatibility status: PASS.

The constructor signature remains `def __new__(cls, *args, **kwargs)`. No new keyword, positional parameter, return type, module export, inheritance relationship, or virtual dispatch call was introduced.

## Public Call Sites and Overrides

Static search found public uses of `Permutation([[...` and `Cycle(...)` in the module docs and public tests. The source change broadens accepted cyclic list input by allowing repeated elements across cycles; it does not require caller changes for existing valid array-form or disjoint cyclic-form inputs.

The public test `raises(ValueError, lambda: Permutation([[1], [1, 2]]))` is incompatible with the new issue intent, so it is classified as SUSPECT legacy behavior rather than a compatibility blocker. Test files were not modified.

## Producer/Consumer Shape

The constructed object still stores `_array_form`, `_size`, and Basic args as before. Existing consumers of `array_form`, `cyclic_form`, `list`, equality, and multiplication continue to receive a normal `Permutation` instance.
