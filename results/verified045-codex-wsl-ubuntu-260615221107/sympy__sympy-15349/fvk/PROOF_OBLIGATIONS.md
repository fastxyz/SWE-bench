# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Domain

For `q = Quaternion(a, b, c, d)`, require
`N = a**2 + b**2 + c**2 + d**2 != 0`. This permits the scale
`s = q.norm()**-2 = 1/N` and excludes the zero quaternion, which does not
represent a rotation.

Finding links: F3.

## PO2: Matrix Equals Hamilton Rotation

For every point `(x, y, z)`, the 3x3 matrix returned by
`to_rotation_matrix()` must produce the vector part of
`q * Quaternion(0, x, y, z) * conjugate(q)`, divided by `N`.

The derived vector components are:

```
x' = ((a**2 + b**2 - c**2 - d**2)*x
      + 2*(b*c - a*d)*y
      + 2*(b*d + a*c)*z) / N

y' = (2*(b*c + a*d)*x
      + (a**2 - b**2 + c**2 - d**2)*y
      + 2*(c*d - a*b)*z) / N

z' = (2*(b*d - a*c)*x
      + 2*(c*d + a*b)*y
      + (a**2 - b**2 - c**2 + d**2)*z) / N
```

This obligation fixes `M12` as `2*(c*d - a*b)/N`.

Finding links: F1, F2.

## PO3: Reported X-Axis Instance

Substitute `a = cos(t/2)`, `b = sin(t/2)`, `c = 0`, `d = 0`. Using
`cos(t/2)**2 + sin(t/2)**2 = 1`, `cos(t) = cos(t/2)**2 - sin(t/2)**2`, and
`sin(t) = 2*sin(t/2)*cos(t/2)`, the matrix must simplify to:

```
[[1, 0, 0],
 [0, cos(t), -sin(t)],
 [0, sin(t),  cos(t)]]
```

Finding links: F1.

## PO4: Existing Z-Axis Convention Is Preserved

Substitute `a = cos(t/2)`, `b = 0`, `c = 0`, `d = sin(t/2)`. The matrix must
simplify to:

```
[[cos(t), -sin(t), 0],
 [sin(t),  cos(t), 0],
 [0,       0,      1]]
```

This matches the existing `to_rotation_matrix` docstring and `rotate_point`
example, so V1 does not switch to the passive convention.

Finding links: F1.

## PO5: Inverse Sign Consistency With from_rotation_matrix

The matrix must satisfy these sign-recovery differences:

```
M21 - M12 = 4*a*b/N
M02 - M20 = 4*a*c/N
M10 - M01 = 4*a*d/N
```

These are the quantities used by `Quaternion.from_rotation_matrix()` to assign
the signs of `b`, `c`, and `d`. With the pre-fix `M12` sign, `M21 - M12` would
collapse to zero for all inputs and could not recover the sign of `b`.

Finding links: F1.

## PO6: 4x4 Point-Rotation Matrix Uses the Corrected 3x3 Block

For `v = (x0, y0, z0)`, the homogeneous translation column must be
`v - M*v`. Therefore any correction to `M12` must flow into
`m13 = y0 - x0*M10 - y0*M11 - z0*M12`.

Finding links: F2.

## PO7: Public Compatibility and Test Handling

The repair must keep `Quaternion.to_rotation_matrix(self, v=None)` callable in
the same way and must not modify test files. Public tests that encode the
pre-fix sign are SUSPECT legacy evidence and may need updates in a normal
project workflow, but this benchmark task forbids editing them.

Finding links: F2.

## PO8: FVK Honesty Gate

The proof must include machine-check commands and label the result
"constructed, not machine-checked" because no K tooling may be run in this
session.

Finding links: F4.
