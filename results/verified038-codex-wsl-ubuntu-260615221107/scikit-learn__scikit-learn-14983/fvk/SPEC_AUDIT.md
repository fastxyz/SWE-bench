# Specification Adequacy Audit

Status: constructed, not machine-checked.

| Claim | Intent entries | Adequacy result | Notes |
| --- | --- | --- | --- |
| C1 | I1, I2, E4, E6 | Pass | Delegating `_RepeatedSplits.__repr__` to `_build_repr` matches the public hint and neighboring splitter design. |
| C2 | I1, I3, I4, E2, E5, E9 | Pass | The claim includes real `n_splits=5` from `cvargs`, not `None` and not object identity. |
| C3 | I2, I3, I4, E2, E5, E9 | Pass | Same storage issue and expected values for `RepeatedStratifiedKFold`. |
| C4 | I5, E6, E7, E8 | Pass | Direct attributes remain authoritative, preserving existing helper behavior. |
| C5 | I5, E6 | Pass | Missing attributes without `cvargs` continue to render as `None`, matching previous `_build_repr` behavior. |
| C6 | I5, E6, E7, E8 | Pass | The issue sample orders `n_splits` before `n_repeats`, but the public hint requires `_build_repr` and the project has public sorted-order repr expectations. The formal claim follows the project convention. |

No formal-English claim is weaker than the public intent: both repeated classes
get meaningful reprs and `n_splits` is recovered from `cvargs`. No formal claim
adds a source-incompatible API requirement.

