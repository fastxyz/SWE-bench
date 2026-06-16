# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal claim | Intent entries | Audit | Notes |
| --- | --- | --- | --- |
| K1 | I1, I2, E2, E3, E4 | Pass | Directly states the public hint: `_af_new` allocates with `cls`. |
| K2 | I1, E1, E3, E5 | Pass | Covers constructor fast paths named in the docstring and issue mechanism. |
| K3 | I1, I3, E5, E7 | Pass | Confirms the existing direct `Basic.__new__(cls, aform)` path already matches intent. |
| K4 | I1, I2, E1, E3 | Pass | Rejects the old behavior where subclass construction could return a base object. |
| K5 | I3, E7 | Pass | This is a compatibility frame condition: requesting `Permutation` from an existing subclass preserves the object as before. |
| K6 | I5, E1, E3 | Pass | The issue's "subclassed properly" language supports preserving subclass on inherited fresh-result operations. |
| K7 | I5, E3 | Pass | Classmethod construction should use the class it is called on. |
| K8 | I4, E6 | Pass | External base aliases are intentionally base-bound and outside subclass dispatch. |

No required behavior is marked fail or ambiguous. The proof remains
constructed, not machine-checked.

