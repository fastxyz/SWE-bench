# Intent Spec

Status: constructed for FVK audit, not machine-checked.

## Public Intent

I1. `Permutation` must be subclassable through normal Python construction.
When a subclass `SubPerm` invokes inherited `Permutation.__new__`, construction
paths that allocate a fresh permutation must allocate `SubPerm`, not the base
`Permutation`.

I2. `_af_new` is the internal fast constructor at the center of the issue. It
must be a classmethod-like operation: `_af_new` called on class `C` with a valid
array form must allocate an object whose class is `C`.

I3. Existing permutation semantics must be preserved: the array form passed to
the fast constructor becomes `_array_form`, and `_size` is the length of that
array. Validation and error behavior outside the subclassing issue are frame
conditions, not repair targets.

I4. Existing module-level aliases that intentionally bind
`Permutation._af_new` should continue to construct plain `Permutation` objects.
The issue is subclass dispatch inside `Permutation`, not replacing all
combinatorics internals with subclass-aware factories.

I5. Methods and classmethods on `Permutation` that create a fresh permutation
from an array form should not collapse a subclass back to `Permutation` when
called through a subclass instance or subclass object. This follows from the
issue's "subclassed properly" phrasing and Python's normal method dispatch
convention.

I6. No execution is available in this session. Tests, Python imports, and K
tooling must not be run; proof commands are artifacts only.

