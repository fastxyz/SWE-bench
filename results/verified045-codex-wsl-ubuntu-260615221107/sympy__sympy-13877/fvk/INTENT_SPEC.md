# Intent Spec

1. The reported no-input-`nan` symbolic matrix determinant path must not return
   `nan` or raise `TypeError("Invalid NaN comparison")`.
2. Bareiss remains valid for symbolic matrices; default determinant behavior
   should not be changed to LU merely because entries are symbolic.
3. Bareiss pivot selection must reject candidates that expand to exact zero.
4. Matrices that already contain `S.NaN` must return `S.NaN` immediately.
5. Public determinant API shape and existing method names must be preserved.

