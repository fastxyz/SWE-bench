# Spec Audit

Status: adequacy comparison between `INTENT_SPEC.md` and `FORMAL_SPEC_ENGLISH.md`.

| Formal item | Intent item(s) | Result | Notes |
| --- | --- | --- | --- |
| FE1 | I1, I2, I3 | PASS | Covers list-of-lists cyclic input, allows cross-cycle repetition, and states left-to-right fold. |
| FE2 | I4 | PASS | The concrete reported input returns identity rather than an error. |
| FE3 | I5 | PASS | Preserves array-form duplicate rejection; this is distinct from cycle-list repetition. |
| FE4 | I3 | PASS | The formal fold matches the public left-to-right order and the existing constructor loop. |
| FE5 | I2, I6 | PASS | Keeps per-cycle validity while removing the cross-cycle disjointness precondition. |
| FE6 | I7 | PASS | Frames singleton/size behavior rather than changing it. |
| FE7 | I8 | PASS | No public API shape changed. |

No formal item is candidate-derived without public-intent support. The only conflicting public evidence is the legacy test `Permutation([[1], [1, 2]])` raising; it is marked SUSPECT in the ledger because it directly conflicts with the issue intent.
