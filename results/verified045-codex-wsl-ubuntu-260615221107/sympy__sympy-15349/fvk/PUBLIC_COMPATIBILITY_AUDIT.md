# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed public symbol: `Quaternion.to_rotation_matrix(self, v=None)`.

Compatibility result: PASS.

- Signature unchanged.
- Return type unchanged: a 3x3 `Matrix` when `v` is not supplied/falsy, and a
  4x4 `Matrix` when a point tuple is supplied.
- Public callsites found by source search are tests and docstring examples; no
  external production callsite in this repository requires a dispatch update.
- The z-axis docstring example remains valid.
- Visible tests for `Quaternion(1, 2, 3, 4)` encode the legacy sign and are
  recorded as SUSPECT in F2, but test files were not modified by this task.
