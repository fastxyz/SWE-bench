# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| `LAZY-REF-PRESERVES-APP-LABEL` | Preserve mixed-case app labels; lowercase model names only. | Pass | Supported by problem text, public hint, `make_model_tuple()`, and app registry semantics. |
| `REPORTED-CASE` | `DJ_RegLogin.Category` must become `DJ_RegLogin.category`. | Pass | Directly covers the issue example. |
| `LEGACY-REPORTED-CASE` | Identify old behavior as failing. | Pass | Included only as discriminator; not used as desired behavior. |
| `CONCRETE-REF-LABEL-LOWER` | Preserve existing concrete-model serialization. | Pass | Supported by `Options.label_lower`. |
| Swappable frame condition | Do not change wrapper behavior. | Pass | Source wraps the already computed value. |

No formal claim is implementation-only without public or source-contract support. No required behavior is marked ambiguous.

