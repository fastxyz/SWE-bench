# Intent Specification

Status: constructed from public evidence only. No tests, Python, or K tooling were run.

## Required Behavior

I1. `Permutation` accepts list-of-lists cyclic input.

Evidence: the issue uses `Permutation([[0,1],[0,1]])`; the constructor docstring describes "list of lists" as cyclic form; public examples show `Permutation([[1, 2]])` and multi-cycle list input.

I2. Cycles in list-of-lists input may be non-disjoint.

Evidence: the issue says "If the cycles passed in are non-disjoint ... I don't see a reason why non-disjoint cycles should be forbidden."

I3. Non-disjoint cycles are applied in left-to-right order.

Evidence: the issue says they "should be applied in left-to-right order and the resulting permutation should be returned." The class docs already describe products of written cycles and show repeated `Permutation(...)(...)` composition.

I4. The concrete input `Permutation([[0, 1], [0, 1]])` constructs the identity permutation on elements `0` and `1`.

Evidence: the issue says it should construct "the identity permutation."

I5. Array-form duplicate rejection remains required.

Evidence: array form is a one-to-one image list; existing public docs say array form must contain integers `0..n-1`, and the public test suite asserts `Permutation([1, 1, 0])` raises. This does not conflict with allowing repeated elements across separate cycles.

I6. Each individual cycle remains a valid cycle.

Evidence: `Cycle.__init__` publicly rejects duplicate elements within a single cycle and negative elements. The issue only removes the disjointness restriction between separate cycles, not per-cycle well-formedness.

I7. Singleton and `size` behavior should be preserved.

Evidence: constructor docs and public tests use singletons to indicate permutation size and use `size` to extend array form. The issue does not request changing this behavior.

I8. The public constructor API must remain compatible.

Evidence: the public symbol is `Permutation.__new__(cls, *args, **kwargs)` and no public intent asks for a signature, return-type, or call protocol change.
