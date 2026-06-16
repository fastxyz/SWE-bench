# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent source | Result | Notes |
| --- | --- | --- | --- |
| EMPTY-TRIPLE | Intent item 5, E-005 | Pass | Preserves visible public branch behavior. |
| PARTIAL-FALLBACK-* | Intent item 5, E-005 | Pass | Preserves missing-component fallback. |
| VALID-COMPLETE | Intent item 5, E-005 | Pass | Preserves valid complete-triple behavior. |
| VALUE-ERROR-COMPLETE | Intent item 4, E-004, E-005 | Pass | Preserves existing invalid-date contract. |
| OVERFLOW-COMPLETE | Intent items 1-3, E-001 through E-003 | Pass | Directly captures the reported crash condition. |
| Public API frame condition | Intent item 6, E-006 | Pass | No signature or dispatch change. |

No formal claim is derived solely from the V1 implementation. The only candidate-derived fact used in the proof is the implementation control-flow shape needed for symbolic execution.

