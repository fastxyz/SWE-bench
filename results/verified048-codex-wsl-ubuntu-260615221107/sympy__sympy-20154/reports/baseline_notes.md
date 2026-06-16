# Baseline Notes

## Root Cause

`sympy.utilities.iterables.partitions` uses `ms` as a mutable working dictionary while it walks the integer partitions. The generator yielded that same `ms` object directly, then mutated it to produce the next partition. As a result, callers that retained yielded values, such as `list(partitions(...))`, held multiple references to the same dictionary and saw them all reflect the final mutation state.

## Files Changed

`repo/sympy/utilities/iterables.py`

- Changed the two iterative yield sites in `partitions` to yield `ms.copy()` instead of `ms`.
- Applied the same copy behavior when `size=True`, so the dictionary inside each `(size, partition)` tuple is also independent.
- Updated the `partitions` docstring to remove the old warning about dictionary reuse and show that `list(partitions(...))` now returns stable partition dictionaries directly.

## Assumptions

- The issue is specifically about the public dictionaries yielded by `partitions`, not about changing the internal partition-generation algorithm.
- A shallow `dict.copy()` is sufficient because partition keys and multiplicities are integers.
- Single-yield edge cases such as invalid limits and the empty partition do not need special handling for reuse because no later mutation occurs within that generator invocation.

## Alternatives Considered

- Rebuilding the generator to allocate a fresh dictionary throughout the algorithm was rejected as unnecessary. Copying only at the public yield boundary fixes retained-output and caller-mutation behavior while preserving the existing internal state machine.
- Returning immutable mappings or tuples was rejected because it would change the documented return type and likely break callers expecting dictionaries.
- Sorting dictionary items before yielding was rejected because the issue is about object reuse, not output ordering, and sorting would add unrelated overhead and alter the insertion order callers currently observe.
