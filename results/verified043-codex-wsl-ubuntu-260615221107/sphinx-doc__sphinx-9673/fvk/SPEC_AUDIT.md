# Spec Audit

Status: constructed for FVK audit, not machine-checked.

| Formal item | Intent match | Audit |
| --- | --- | --- |
| C-1 | I-1, I-4 | Pass. It states the documented-mode return annotation injection rule. |
| C-2 | I-2, I-3, I-4 | Pass. It is the missing issue case: `returns` is a documented return description. |
| C-3 | I-2, E-9 | Pass. It preserves the existing `return` spelling behavior. |
| C-4 | I-5 | Pass. It prevents duplicate return type fields. |
| C-5 | I-6 | Pass. It preserves the `"documented"` target restriction. |
| C-6 | I-1 | Pass. No annotation means there is no return type value to add. |
| F-C-1 | I-7 | Pass. The source edit is isolated to the return-description alias condition and does not alter parameter branches. |
| F-C-2 | I-8 | Pass. The source edit changes no public API, hook, config, or Napoleon output. |

No formal-English claim is candidate-only or legacy-only. The V1 code change is
justified by public issue text, Python-domain field aliases, and Napoleon's
documented output shape.
