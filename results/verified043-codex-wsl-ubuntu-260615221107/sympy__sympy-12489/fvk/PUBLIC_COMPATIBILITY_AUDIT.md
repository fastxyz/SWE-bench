# Public Compatibility Audit

Status: constructed for FVK audit, not machine-checked.

## Changed Public Or Semi-Public Symbols

`Permutation._af_new`

- V1 changed it from `staticmethod` to `classmethod`.
- Class call compatibility: `Permutation._af_new(array)` still accepts one user
  argument because Python binds the class automatically.
- Subclass call behavior: `SubPerm._af_new(array)` now allocates `SubPerm`, which
  is the intended fix.
- Existing module aliases that execute `_af_new = Permutation._af_new` remain
  bound to the base class and therefore keep producing base `Permutation`
  objects.
- Status: compatible and intent-aligned.

`Permutation.__new__`

- V1 routes fast paths through `cls._af_new` and leaves the existing direct
  `Basic.__new__(cls, aform)` path intact.
- Constructing a subclass from a base `Permutation` now creates the subclass.
  This is an intentional behavior change required by the issue.
- Constructing `Permutation` from an existing subclass still returns the
  existing object because it is already an instance of the requested class.
- Status: compatible, with the required subclassing correction.

`Permutation.rmul_with_af`

- V1 changed it from `staticmethod` to `classmethod` so subclass calls can
  preserve the called class.
- Public call shape `Permutation.rmul_with_af(*args)` remains unchanged.
- `perm_groups.py` binds `rmul = Permutation.rmul_with_af`; after binding, this
  remains a callable accepting `*args`, now with `Permutation` already bound.
- Status: compatible by call shape; no source edit needed.

Instance and class methods that now call `self._af_new`, `cls._af_new`, or
`self.__class__`

- Affected behavior is result class identity, not permutation array algebra.
- This is justified by the issue's subclassing intent and Python method
  dispatch conventions.
- Status: compatible with intended subclassing; no unhandled public override was
  found in source inspection.

