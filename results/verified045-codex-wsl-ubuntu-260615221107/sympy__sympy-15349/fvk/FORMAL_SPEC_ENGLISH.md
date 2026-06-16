# Formal Spec English

Status: constructed, not machine-checked.

1. Claim `TO-ROTATION-MATRIX`: for every nonzero quaternion
   `Quaternion(a, b, c, d)`, `to_rotation_matrix()` returns the 3x3 matrix whose
   entries are listed in `fvk/SPEC.md`; in particular `M12` is
   `2*(c*d - b*a)/(a**2 + b**2 + c**2 + d**2)`.
2. Claim `MATRIX-APPLIES-HAMILTON-ROTATION`: for every point `(x, y, z)`, the
   returned 3x3 matrix sends the point to the vector part of
   `q * Quaternion(0, x, y, z) * conjugate(q)`, scaled by the squared norm.
3. Claim `REPORTED-X-AXIS`: for
   `Quaternion(cos(t/2), sin(t/2), 0, 0)`, the matrix simplifies to the x-axis
   active rotation matrix with `(1, 2) = -sin(t)` and `(2, 1) = sin(t)`.
4. Claim `POINT-ROTATION-ABOUT-V`: when a point `v` is supplied, the 4x4
   translation column is `v - M*v`, so the transform fixes `v` and rotates about
   that point.
5. Side condition: the proof excludes the zero quaternion because the scale
   `1 / norm(q)**2` is undefined there.
