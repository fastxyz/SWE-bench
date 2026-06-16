# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO-1 | Cyclic list input is in domain when each individual cycle is valid, even if cycles overlap. | E1-E4, I1-I3 | Discharged by `CONSTRUCT-CYCLES-NONDISJOINT` claim. |
| PO-2 | Cross-cycle duplicates must not trigger the array duplicate `ValueError`. | E2-E4 | Discharged by source guard `if not is_cycle and has_dups(temp)` and the absence of `hasCrossCycleDups` from the rejecting rule. |
| PO-3 | Cycles in a list are applied left to right. | E3, E5, E9 | Discharged by the fold rule `foldCycles(C ; CS, M) => foldCycles(CS, composeCycle(M, C))` and the constructor loop `for ci in args: c = c(*ci)`. |
| PO-4 | `Permutation([[0, 1], [0, 1]])` returns identity array `[0, 1]`. | E2 | Discharged by `ISSUE-IDENTITY` claim and concrete fold equations swap01 followed by swap01 -> identity. |
| PO-5 | Array-form duplicates still raise. | E7 | Discharged by `ARRAY-DUPLICATES-REJECTED` claim and unchanged array duplicate guard. |
| PO-6 | Singleton and `size` behavior are preserved. | E6 | Framed: V2 does not change singleton handling or the `if size and size > len(aform)` extension branch. |
| PO-7 | Invalid individual cycles remain rejected. | E10 | Framed through unchanged `Cycle(*ci)` construction inside the cyclic fold. |
| PO-8 | Public API compatibility is preserved. | I8 | Discharged by static compatibility audit: no signature, return shape, dispatch, or storage protocol changed. |

## Open Verification Conditions

No semantic code bug remains open under this spec. The only open condition is machine checking: `kompile`/`kprove` were not run because this task forbids execution.
