# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Result | Notes |
| --- | --- | --- | --- |
| FE1 | I1, I4 | Pass | Directly encodes owner-sensitive equality. |
| FE2 | I3 | Pass | Equal fields necessarily share the hash key. |
| FE3 | I2 | Pass | The reported set cardinality bug is covered. |
| FE4 | I4, I5 | Pass | Creation-counter-primary order is explicit. |
| FE5 | I4 | Pass with scoped default assumption | Public intent requires a same-counter tie-breaker but does not specify same-label/different-class ordering. The identity component is a deterministic process-local tie-breaker for totality within the modeled run and is used only after the public counter-first obligation. |
| FE6 | I6 | Pass | V1 does not change method signatures or public call shapes. |

No formal item is candidate-derived without public or implementation-semantics
support. The only under-specified point is the exact ordering of two different
model objects with the same model label; the spec treats this as a tie-breaker
detail that does not affect the reported issue or normal different-counter
ordering.
