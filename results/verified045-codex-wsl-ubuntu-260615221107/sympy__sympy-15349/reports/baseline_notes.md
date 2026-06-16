# Baseline Notes

## Root cause

`Quaternion.to_rotation_matrix()` used the same positive `q.b*q.a` term for both
the `(1, 2)` and `(2, 1)` off-diagonal entries of the 3x3 matrix. For a
quaternion representing an active rotation about the x-axis,
`Quaternion(cos(x/2), sin(x/2), 0, 0)`, this made both sine terms positive:

```
[1,      0,      0]
[0, cos(x), sin(x)]
[0, sin(x), cos(x)]
```

The quaternion rotation convention used by `rotate_point()` and by the
`to_rotation_matrix()` z-axis example requires those entries to have opposite
signs. The `(1, 2)` entry should subtract `q.b*q.a`, while `(2, 1)` should keep
the positive term.

## Files changed

- `repo/sympy/algebras/quaternion.py`: changed the `m12` formula in
  `Quaternion.to_rotation_matrix()` from `2*s*(q.c*q.d + q.b*q.a)` to
  `2*s*(q.c*q.d - q.b*q.a)`. This fixes the x-axis rotation matrix and also
  corrects the 4x4 point-rotation transform because its translation terms are
  computed from the same matrix entries.

## Assumptions and alternatives considered

- Assumed `to_rotation_matrix()` should match the active quaternion rotation
  convention already used by `Quaternion.rotate_point()`, where points are
  transformed with `q * point * conjugate(q)`.
- Considered flipping the `(2, 1)` entry instead, but rejected it because the
  existing z-axis example in `to_rotation_matrix()` already uses the active
  convention, and the standard active quaternion matrix has a negative
  `q.b*q.a` contribution in `(1, 2)` and a positive one in `(2, 1)`.
- Assumed no test files should be changed. The task explicitly fixes behavior
  in source only, and the hidden tests should encode the corrected matrix.
