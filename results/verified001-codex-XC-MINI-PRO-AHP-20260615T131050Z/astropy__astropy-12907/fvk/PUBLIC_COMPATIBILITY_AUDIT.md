# Public Compatibility Audit

Status: constructed, not machine-checked.

Changed source symbol: private helper `astropy.modeling.separable._cstack`.

Signature change: none.

Return type change: none. The helper still returns a NumPy matrix assembled by
`np.hstack`; `separability_matrix` still returns a boolean matrix after
`np.where`.

Public dispatch change: none. `_operators['&']` still maps to `_cstack`.

Public API symbols changed: none. `is_separable` and `separability_matrix`
remain unchanged.

Compatibility result: pass. The edit changes only the contents of the
lower-right block for ndarray right operands, which is the intended bug fix.
