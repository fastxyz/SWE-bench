# Spec Audit

Status: adequacy gate for constructed, not machine-checked proof.

| Formal claim | Intent obligation | Audit | Notes |
| --- | --- | --- | --- |
| C1 | I1, I3, I4 | Pass | Total-degree lower-bound acceptance is exactly the documented integer-mode behavior. |
| C2 | I1 | Pass | Rejecting candidates below `min_degree` follows directly from the documented lower bound. |
| C3 | I3 | Pass | The issue explicitly names mixed degree-3 monomials as expected. |
| C4 | I3 plus E5 | Pass | This is a negative adequacy claim: it shows why the legacy predicate cannot be the spec. |
| C5 | I5 | Pass | The empty-variable boundary follows from the same total-degree contract and the public tests identifying `1` as the degree-zero monomial. |
| C6 | I7 | Pass | List mode has separate per-variable intent and is intentionally framed unchanged. |
| C7 | I8 | Pass | No public source imposes generator order. |

No formal-English claim is weaker than public intent for the audited integer branch. The only abstraction limitation is full SymPy expression construction/canonicalization; that is recorded in `FINDINGS.md` as proof capability gap F4, not used to weaken the total-degree obligation.
