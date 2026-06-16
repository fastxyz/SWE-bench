# Intent Spec

Status: constructed from public intent before accepting V1 behavior as the
specification.

## Required behavior

1. `Pipeline` must implement `__len__` so that `len(pipe)` is defined.
2. `len(pipe)` must return the number of configured pipeline steps.
3. `pipe[:len(pipe)]` must be evaluable through the existing slice support and
   represent the full pipeline prefix.
4. The fix should add as little sequence behavior as possible; in particular,
   the public hints say not to implement broader sequence methods such as
   `__iter__`.
5. Existing integer, string-name, and slice indexing behavior should be
   preserved.

## Domain

The intended domain is `Pipeline` instances whose `steps` attribute is a sized
sequence of `(name, estimator)` pairs. The public docstring says `steps : list`,
and valid construction requires at least one step with a final estimator. The
formal cardinality claim is stated for any non-negative step count, which also
covers the method body if `steps` is later reassigned to an empty sized
sequence.

## Default-domain assumptions

1. Python `len` on a sequence-like object returns the sequence cardinality.
2. Python prefix slicing with a stop equal to the sequence length returns the
   complete sequence.
3. Partial correctness is sufficient for this audit. There are no loops or
   recursion in the added method.
