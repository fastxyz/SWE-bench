# Spec Audit

| Formal clause | Intent clause | Result | Notes |
|---|---|---|---|
| C-001 fresh consecutive ids | IS-003, IS-004 | pass | Fresh ids model independent Python dictionary objects. |
| C-001 heap content equals `STATES` maps | IS-001, IS-003 | pass | Snapshot content is preserved after later generator steps. |
| C-002 size-mode fresh ids and heap content | IS-002, IS-003, IS-004 | pass | Covers the `P` component of `(M, P)` yields. |
| C-002 size component preserved | IS-002 | pass | The formal state stores size alongside the copied map. |
| C-003 abstract partition enumeration sequence | IS-005, IS-006 | pass with boundary | Adequate for this repair because V1 does not change the enumeration transition. Full enumeration proof is explicitly not claimed. |
| C-004 partial, constructed proof | IS-006 | pass | Honesty gate is explicit; no tool execution or test deletion is claimed. |

Adequacy verdict: pass for the aliasing/snapshot repair. The only boundary is full integer-partition enumeration correctness, which is unchanged by V1 and remains covered by public tests rather than this constructed proof.
