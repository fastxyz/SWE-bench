# Spec Audit

| Formal English Item | Intent Coverage | Verdict |
| --- | --- | --- |
| TypeVar-like key normalizes to string before `_make_subclass` display concatenation. | Directly matches E1-E3. | PASS |
| String names keep dotted display behavior. | Directly matches E4 and existing mock tests. | PASS |
| In-domain non-string names normalize via string `__name__` or string `repr()`. | Supported by E5 and default Python object-domain assumptions. | PASS |
| `_MockObject.__getitem__` is included in the proof. | Required by E6 because the reported generic-class path reaches `_make_subclass` through subscription. | PASS |
| The model does not specify bracketed generic display syntax. | No public evidence requires bracketed display, and existing public tests support dotted display. | PASS |

No formal-English claim is weaker than the public intent. The proof does not
claim full Python generic alias semantics; that would be stronger than the
issue's expected behavior and is unnecessary for the reported autodoc failure.
