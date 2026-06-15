# Spec Audit

Status: adequacy gate for the constructed FVK spec.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| K1 ESCAPE-OBJECT | I1, I2, I3, I6 | PASS | Captures delegation through stdlib escaping, `str()` coercion, and safe output. |
| K2 ESCAPE-SAFE-INPUT | I2, E7 | PASS | Preserves "always escape" behavior for already-safe input. |
| K3 APOSTROPHE-USES-STDLIB-SPELLING | I4, E5 | PASS | The changed literal is explicitly allowed by the public issue. |
| K4 CORE-CHARACTERS | I3, E6 | PASS | Covers all named character classes from the public docstring and stdlib helper. |
| K5 URLIZE-X27-COMPATIBILITY | I7, E10 | PASS | This is a module-internal compatibility consequence of the new apostrophe spelling. |
| K6 public callable frame | I6 | PASS | No signature or import path changed. |
| K7 trusted stdlib abstraction | D3 | PASS WITH CAVEAT | Appropriate for this targeted proof; full stdlib verification is outside scope. |

No formal-English obligation is weaker than the intent. No obligation preserves
the legacy `&#39;` spelling as required behavior; public tests that assert it are
classified as SUSPECT legacy evidence in `FINDINGS.md`.
