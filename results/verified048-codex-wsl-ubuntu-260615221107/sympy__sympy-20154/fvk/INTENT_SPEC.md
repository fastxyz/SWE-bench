# Intent Spec

Status: intent-only public specification for `sympy.utilities.iterables.partitions`, written before accepting candidate behavior as correct.

## Required Behaviors

IS-001: `partitions(n, m=None, k=None, size=False)` yields partition dictionaries. Each dictionary maps a part size to its multiplicity.

IS-002: The optional `size=True` mode yields `(M, P)` where `P` is the partition dictionary and `M` is the sum of `P`'s multiplicities.

IS-003: Retaining yielded dictionaries must be safe. A caller that materializes the iterator, for example with `list(partitions(...))`, must receive stable dictionary contents for each partition rather than multiple references that later all show the final internal state.

IS-004: Each yielded partition dictionary must be independent from the generator's internal mutable working dictionary. Mutating a yielded dictionary must not corrupt later generation, and later generator mutations must not change earlier yielded dictionaries.

IS-005: The repair should preserve the existing partition enumeration, filtering by `m` and `k`, boundary behavior for empty/impossible cases, public signature, and return shape. The public issue licenses copying before yield as an acceptable performance tradeoff.

IS-006: Full termination and full integer-partition enumeration correctness are outside this repair's new behavioral change, but existing public tests and documentation remain compatibility evidence that should not be regressed.
