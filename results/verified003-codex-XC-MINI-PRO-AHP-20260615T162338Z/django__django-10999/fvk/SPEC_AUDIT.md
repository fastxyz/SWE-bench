# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Audit result | Notes |
| --- | --- | --- | --- |
| `STD-NODAYS-POS` | Intent 2 and 6 | Pass | Preserves positive standard forms. |
| `STD-NODAYS-NEG` | Intent 3 | Pass | Captures the final issue interpretation that leading `-` negates the whole no-day time value. |
| `STD-DAYS-PRESERVE` | Intent 5 | Pass | Preserves Python/Django signed-day roundtrip behavior. |
| `STD-DAYS-SIGNED-TIME-INVALID` | Intent 4 and 5 | Pass | Prevents an additional internal time sign in standard format while keeping PostgreSQL parsing separate. |
| `STD-INTERNAL-SIGN-INVALID` | Intent 4 | Pass | Rejects signs after colons. |
| `REPORTED-HMS` | Intent 3 | Pass | Concrete issue case derives from `STD-NODAYS-NEG`. |
| `REPORTED-MS` | Intent 3 | Pass | Concrete issue-hint case derives from `STD-NODAYS-NEG`. |
| Abstraction to parsed input shapes | Default-domain assumptions | Pass with caveat | The abstraction distinguishes passing and failing sign-placement cases, but it is not a full proof of Python regex behavior. |

No formal-English claim is candidate-derived without public support. The only
legacy-derived public-test expectations found are marked suspect in
`FINDINGS.md` and are not used to justify the spec.
