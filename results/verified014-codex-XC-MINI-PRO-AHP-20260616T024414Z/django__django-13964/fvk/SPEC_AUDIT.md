# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Rationale |
| --- | --- | --- | --- |
| C1 empty local FK refresh | I1, I2 | PASS | The claim states exactly the issue trace's required transition from `""` to the saved related object's primary key. |
| C2 unsaved related object guard | I3 | PASS | The claim preserves the pre-existing `obj.pk is None` protection and prevents the fix from weakening it. |
| C3 non-empty mismatch cache clear | I4, I5 | PASS | The claim preserves existing behavior outside the stale-empty-value repair and keeps cache invalidation after comparison. |
| Loop/frame obligation | D1, D3 | PASS WITH ABSTRACTION | The K model is per-field. The source loop is finite and each iteration mutates only the current field's local relation value/cache or raises. This abstraction distinguishes the reported failing and passing states. |
| Use of `field.empty_values` | E5, D2 | PASS | Public hint and Django base `Field.empty_values` support treating `""` as empty in the CharField primary-key case. |

No formal-English claim is candidate-derived without public intent support. No
claim preserves the buggy legacy behavior where `product_id == ""` is written
after the related object's primary key becomes `"foo"`.
