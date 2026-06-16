# Public Compatibility Audit

Target public symbol: `sympy.utilities.iterables.partitions`.

## API Shape

- Signature unchanged: `partitions(n, m=None, k=None, size=False)`.
- `size=False` return element shape unchanged: dictionary mapping part size to multiplicity.
- `size=True` return element shape unchanged: `(M, P)` tuple, where `P` is a dictionary.
- Mutability of returned dictionaries is preserved. The change is identity isolation, not an immutable return type.

## Public Callsite Scan

- Public tests use `[p.copy() for p in partitions(...)]`. These remain valid because dictionary equality and contents are preserved; caller-side copying is no longer required for correctness.
- Public tests compare `len(list(partitions(...)))`; counts are unchanged because the generator's internal transition logic is unchanged.
- `IntegerPartition(p) for p in partitions(i)` continues to receive dictionaries.
- Internal consumers in `multiset_partitions` and `partitions`-based set partition helpers continue to receive dictionaries and iterate `p`/`p.items()`.

Compatibility verdict: pass. V1 changes only object identity isolation at the yield boundary and preserves public signature, return types, tuple shape, value equality, and ordering of generator yields.
