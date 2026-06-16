# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent entries | Result | Notes |
| --- | --- | --- | --- |
| LOC-GENERIC | I1, I2, I3, E3, E5, E7 | pass | The claim says `.loc` preserves the mapping as `indexers`, matching the public dictionary-indexing contract. |
| LOC-METHOD-CONCRETE | I2, E1, E2, E4 | pass | The concrete public reproducer is represented directly. |
| HELPER-METHOD-CONCRETE | I5, E3, E7 | pass | The helper claim covers the same reserved-name collision after dynamic `{dim: value}` construction. |
| HELPER-GENERIC | I5, E3, E7 | pass | The generic helper claim is stronger than the concrete `method` example but follows from the public dimension-name irrelevance statement. |
| LEGACY-METHOD-COUNTEREXAMPLE | E4 | pass as diagnostic only | This is not an expected behavior. It shows that the modeled mechanism can reproduce the public symptom. |
| Frame claim | I4, I6, E7, E8 | pass | The proof does not change `.sel` parameter semantics or downstream label lookup. |

No formal-English item is marked fail or ambiguous.

Adequacy conclusion: the K claims prove the dispatch property required by the
public issue, assuming the mini semantics faithfully models Python argument
binding for the audited call shapes. The proof is constructed, not
machine-checked.
