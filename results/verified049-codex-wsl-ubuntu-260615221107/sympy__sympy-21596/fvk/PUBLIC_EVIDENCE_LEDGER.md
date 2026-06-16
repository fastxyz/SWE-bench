# Public Evidence Ledger

Status: constructed, not machine-checked.

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | prompt | "`2 in S1.intersect(Reals)` ... `True`. This output is incorrect." | Membership in the real intersection must not admit `2` for the reported set. | Encoded in SPEC, claims, and PO1. |
| E2 | prompt | "Correct output ... `2 in S1.intersect(Reals)` ... `False`" | `contains(2, S1.intersect(S.Reals)) == False`. | Encoded in SPEC, claims, and PO1. |
| E3 | prompt | "Correct output ... `S1.intersect(S2)` ... `{-1, 1}`" | The reported image set's intersection with reals is exactly `FiniteSet(-1, 1)`. | Encoded in SPEC, claims, and PO2. |
| E4 | math/default-domain | `n + I*(n - 1)*(n + 1)` is real iff `(n - 1)*(n + 1) == 0`. | The base set must be restricted to roots `n = -1, 1`. | Encoded in SPEC, claims, and PO2. |
| E5 | source/public test | `imageset(Lambda(n, 1/n), S.Integers).is_subset(S.Reals) is None` | Undefined denominator points must remain exclusions and must not make `is_subset(S.Reals)` conclude true. | Encoded as frame/compatibility PO3. |
| E6 | source/public test | `Complement(S.Integers, FiniteSet((-1, 1)))` expected for the reported expression | SUSPECT legacy expectation: it conflicts with E2 and E3. | Recorded as Finding F2; not used as a positive spec. |
| E7 | implementation | `expand_complex` is called with `mul=False` and `multinomial=False`; `Mul.as_real_imag` preserves the issue expression's real factors. | The linear-factor helper is applicable to `(n - 1)*(n + 1)` on the reported path. | Supports V1 confirmation; recorded in PROOF. |
| E8 | implementation | V1 changes `base_set -= roots` to `base_set = base_set.intersect(roots)`. | Candidate implementation matches E3 for enumerated zero-imaginary roots. | Confirmed by PO2. |

