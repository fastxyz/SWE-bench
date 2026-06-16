# Spec Audit

Status: constructed, not machine-checked.

| Formal-English Item | Intent Item | Verdict | Notes |
| --- | --- | --- | --- |
| MOD Decimal/Integer resolves to Decimal. | Required behavior 2; Evidence E2. | Pass | Directly matches the reported issue. |
| MOD Integer/Decimal resolves to Decimal. | Required behavior 2 plus expression operand symmetry. | Pass | Required because either operand can appear on either side of `%`. |
| MOD Decimal/Integer subclass resolves to Decimal. | Default-domain assumption and Evidence E7. | Pass | Captures `issubclass()`-based behavior without changing source signatures. |
| MOD Integer/Float and Float/Integer resolve to Float. | Required behavior 1 and Evidence E5. | Pass | Entailed by adding MOD to the existing mixed numeric family. |
| Mixed Decimal/Integer POW remains `noType`. | Required behavior 3 and Evidence E6. | Pass | Avoids over-expanding the fix beyond the issue and table contract. |

No formal claim is marked fail or ambiguous. The claims intentionally do not
cover backend SQL arithmetic values, because the public issue is about
`output_field` resolution.
