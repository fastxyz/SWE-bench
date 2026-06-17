# Iteration Guidance

Status: V1 stands unchanged.

## Decision

Keep the V1 source patch in `repo/sympy/physics/units/unitsystem.py`.

The FVK audit confirms the patch discharges the public issue intent:
equivalent dimensions in an addition are accepted by consulting the active
dimension system. The audit also confirms that incompatible dimensions still
raise `ValueError`, return shape is unchanged, and no public call site needs an
update.

## No Additional Source Change

Do not canonicalize the returned dimension. The existing accepted-addition
behavior returns the first addend's dimension expression, and the public issue
does not require a canonical representative.

Do not alter `Dimension.__eq__`, `Dimension.__add__`, or the global dimension
definitions. Equivalence depends on a specific `DimensionSystem`, and the
current fix is located where that context is available.

Do not change test files in this task.

## Future Tests To Add Outside This Task

After code execution is available, add focused tests for:

- `a1*t1 + v1` under SI does not raise and returns the combined factor with an
  equivalent velocity dimension.
- A reversed addend order also accepts equivalent dimensions.
- Length plus time still raises `ValueError`.
- A `UnitSystem` without a dimension system keeps direct-equality behavior.

## Machine-Checking Follow-Up

Run the commands recorded in `fvk/PROOF.md` only in an environment where K
tooling is available. Until `kprove` returns `#Top`, treat the proof as
constructed, not machine-checked.
