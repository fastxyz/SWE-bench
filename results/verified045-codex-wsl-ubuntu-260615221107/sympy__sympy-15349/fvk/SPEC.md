# FVK Specification: Quaternion.to_rotation_matrix

Status: constructed, not machine-checked. No tests, Python, or K tools were run.

## Target

`repo/sympy/algebras/quaternion.py`, method
`Quaternion.to_rotation_matrix(self, v=None)`.

## Intent-Only Contract

For any nonzero quaternion `q = a + b*i + c*j + d*k`, `to_rotation_matrix()`
returns the 3x3 matrix that applies the same active rotation to a point as
`q * point * conjugate(q)`, scaled by `1 / (a**2 + b**2 + c**2 + d**2)` so that
non-unit quaternions are accepted.

For `v = (x, y, z)`, `to_rotation_matrix(v)` returns the homogeneous 4x4
matrix whose upper-left 3x3 block is the same rotation matrix and whose
translation column is `v - M*v`, so the rotation is about point `v`.

The zero quaternion is outside this contract because it does not represent a
rotation and the formula requires division by its squared norm.

## Formal Postcondition

Let

```
N = a**2 + b**2 + c**2 + d**2
s = 1 / N
```

with precondition `N != 0`. The 3x3 result must be:

```
M00 = 1 - 2*s*(c**2 + d**2)
M01 = 2*s*(b*c - d*a)
M02 = 2*s*(b*d + c*a)

M10 = 2*s*(b*c + d*a)
M11 = 1 - 2*s*(b**2 + d**2)
M12 = 2*s*(c*d - b*a)

M20 = 2*s*(b*d - c*a)
M21 = 2*s*(c*d + b*a)
M22 = 1 - 2*s*(b**2 + c**2)
```

The required repaired entry is `M12 = 2*s*(c*d - b*a)`. Its transpose-side
counterpart `M21 = 2*s*(c*d + b*a)` keeps the positive sign.

If `v = (x, y, z)`, the 4x4 result must be:

```
[[M00, M01, M02, x - x*M00 - y*M01 - z*M02],
 [M10, M11, M12, y - x*M10 - y*M11 - z*M12],
 [M20, M21, M22, z - x*M20 - y*M21 - z*M22],
 [0,   0,   0,   1]]
```

## Public Evidence Ledger

E1. Source: prompt. Quote: `Quaternion(cos(x/2), sin(x/2), 0, 0)` produced a
matrix with both off-diagonal x-axis sine terms positive, followed by "One of
the `sin(x)` functions should be negative." Obligation: the x-axis rotation
matrix for that quaternion must have opposite signs in entries `(1, 2)` and
`(2, 1)`. Status: encoded by the `M12` negative sign and proof obligation PO3.

E2. Source: method docstring/name. Quote: "Returns the equivalent rotation
transformation matrix of the quaternion which represents rotation about the
origin if v is not passed." Obligation: matrix output must be equivalent to the
rotation represented by the quaternion, not just an arbitrary matrix shape.
Status: encoded by the equivalence-to-`q * point * conjugate(q)` claim PO2.

E3. Source: `rotate_point` implementation and docstring. Quote: it computes
`q * Quaternion(0, pin[0], pin[1], pin[2]) * conjugate(q)` and the z-axis
example rotates `(1, 1, 1)` to
`(sqrt(2)*cos(x + pi/4), sqrt(2)*sin(x + pi/4), 1)`. Obligation: use the active
rotation convention; the z-axis matrix is
`[[cos(x), -sin(x), 0], [sin(x), cos(x), 0], [0, 0, 1]]`. Status: encoded by
PO2 and PO4.

E4. Source: `from_rotation_matrix` implementation. Quote: signs are recovered
from `M[2, 1] - M[1, 2]`, `M[0, 2] - M[2, 0]`, and `M[1, 0] - M[0, 1]`.
Obligation: the matrix entries must be antisymmetric in the quaternion-vector
cross terms, including `M21 - M12 = 4*a*b/N`. Status: encoded by PO5.

E5. Source: public in-repo tests. Quote: visible tests for
`Quaternion(1, 2, 3, 4).to_rotation_matrix()` expect `M12 = 14/15`, equal to
the pre-fix same-plus expression. Obligation: SUSPECT legacy evidence because
it conflicts with E1-E4; it must not override the prompt-derived contract.
Status: finding F2.

E6. Source: default-domain assumption and method wording. Quote: "quaternion
which represents rotation." Obligation: the quaternion must be nonzero, because
the zero quaternion cannot represent a rotation and `s = norm(q)**-2` is
undefined there. Status: precondition PO1 and finding F3.

## Formal Claim Summary

The machine-checkable core is sketched in `fvk/mini-quaternion.k` and
`fvk/quaternion-rotation-spec.k`.

- Claim `TO-ROTATION-MATRIX`: from a nonzero quaternion, the method returns the
  matrix in the formal postcondition above.
- Claim `MATRIX-APPLIES-HAMILTON-ROTATION`: multiplying the returned matrix by
  a point `(x, y, z)` yields the vector part of
  `q * Quaternion(0, x, y, z) * conjugate(q)`.
- Claim `REPORTED-X-AXIS`: substituting
  `q = Quaternion(cos(t/2), sin(t/2), 0, 0)` yields
  `[[1, 0, 0], [0, cos(t), -sin(t)], [0, sin(t), cos(t)]]` after standard trig
  identities.
- Claim `POINT-ROTATION-ABOUT-V`: for `v` present, the homogeneous transform is
  `M*p + (v - M*v)`, hence fixes `v` and rotates about that point.

## Public Compatibility

No public method signature, return type, dispatch shape, or import path changes.
The only production behavior change is the symbolic value of entry `(1, 2)` and
the dependent 4x4 translation entry for nonzero quaternions with `b*a != 0`.
