# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Audit |
| --- | --- | --- |
| CASE-DISTINCT-REGISTRATION | I-001, I-002 | pass: exactly captures the reported `MySQL`/`mysql` duplicate bug. |
| EXACT-DUPLICATE-WARNS | I-002 | pass: preserves existing public exact-duplicate warning behavior. |
| TERM-ROLE-COMPAT-SHAPE | I-004 | pass: formalizes the compatibility condition V1 missed. |
| EXACT-TERM-RESOLUTION | I-003 | pass: exact spelling is needed to distinguish case-distinct terms. |
| UNAMBIGUOUS-FOLD-FALLBACK | I-005 | pass: preserves old case-insensitive behavior only when it cannot choose the wrong target. |
| AMBIGUOUS-FOLD-REFUSES-GUESS | I-003, I-005 | pass: prevents the compatibility fallback from collapsing distinct case variants. |
| ANY-TERM-USES-SAME-RESOLVER | I-006 | pass: aligns `:any:` with the term object identity rule. |

No claim is supported only by current implementation behavior. The only
implementation-derived obligation is compatibility with the previous lowercased
pending-xref shape; it is independently justified by the public intersphinx
consumer path that uses `reftarget` directly.
