# SPEC_AUDIT.md

Status: adequacy gate for the constructed formal claims.

| Formal English item | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| META-DIRECT | 1 | pass | Direct support for `Meta.formfield_callback`. |
| TOP-LEVEL-OVERRIDE | 3, 5 | pass | Preserves existing explicit override path. |
| TOP-LEVEL-NONE-DISABLES | 5 | pass | Applies only to explicit class attributes, not factory default omission. |
| FACTORY-OMITTED-PRESERVES-META | 2, 4 | pass | Main reported bug. |
| FACTORY-EXPLICIT-OVERRIDES-META | 3, 8 | pass | Existing explicit callback behavior remains. |
| FACTORY-FALSEY-NON-NONE-OVERRIDES | 7 | pass | Uses identity with `None`, not truthiness. |
| INHERITED-META-PRESERVES | 6 | pass | Normal Python resolution: no child `Meta` means parent `Meta`. |
| REPLACED-META-DOES-NOT-LEAK-BASE | 6 | pass | This failed in V1 because V1 had an extra base-callback fallback. V2 fixes it. |

No formal-English claim is candidate-derived without public intent support. No
ordering or winner rule is preserved solely from legacy behavior.
