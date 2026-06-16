# Intent Spec

Status: constructed, not machine-checked.

1. `Quaternion.to_rotation_matrix()` must return the matrix for the rotation
   represented by the quaternion.
2. The rotation convention is active, matching `Quaternion.rotate_point()`,
   which computes `q * point * conjugate(q)`.
3. For `Quaternion(cos(x/2), sin(x/2), 0, 0)`, the x-axis off-diagonal sine
   terms must have opposite signs; specifically the matrix has
   `(1, 2) = -sin(x)` and `(2, 1) = sin(x)`.
4. Existing z-axis examples must remain
   `[[cos(x), -sin(x), 0], [sin(x), cos(x), 0], [0, 0, 1]]`.
5. For `v = (x, y, z)`, the 4x4 matrix must rotate about point `v` by using
   translation `v - M*v`.
6. The verified domain is nonzero quaternions. The zero quaternion is not a
   rotation quaternion.
