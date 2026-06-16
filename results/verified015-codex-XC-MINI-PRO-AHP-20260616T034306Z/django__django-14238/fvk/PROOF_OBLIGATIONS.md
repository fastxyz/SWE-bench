# Proof Obligations

Status: constructed, not machine-checked. The K commands below are recorded for
later checking and were not executed.

## Obligations

| ID | Claim | Evidence | Status |
| --- | --- | --- | --- |
| O1 | For all classes `C`, `subclassOf(C, bigAutoField) => autoFieldSubclassCheck(C) == true`. | SPEC E1, E3, E4, E9, E10 | Discharged constructively by `tupleSubclassCheck(C)`. |
| O2 | For all classes `C`, `subclassOf(C, smallAutoField) => autoFieldSubclassCheck(C) == true`. | SPEC E1, E3, E4, E9 | Discharged constructively by `tupleSubclassCheck(C)`. |
| O3 | For all classes `C`, `subclassOf(C, autoField) => autoFieldSubclassCheck(C) == true`. | SPEC E5 | Discharged constructively by the unchanged `superAutoFieldSubclassCheck(C)` disjunct. |
| O4 | For all classes `C`, if `C` is not a subclass of `bigAutoField`, `smallAutoField`, or `autoField`, then `autoFieldSubclassCheck(C) == false`. | SPEC E7 | Discharged constructively by all disjuncts evaluating false. |
| O5 | `defaultPkCheck(imported(customBigAutoField)) == accepted(customBigAutoField)`. | SPEC E1, E2, E10 | Discharged constructively by O1 and the accepting validation branch. |
| O6 | `defaultPkCheck(imported(customSmallAutoField)) == accepted(customSmallAutoField)`. | SPEC E1 | Discharged constructively by O2 and the accepting validation branch. |
| O7 | `defaultPkCheck(imported(indirectCustomBigAutoField)) == accepted(indirectCustomBigAutoField)`. | SPEC E3 | Discharged constructively by transitive subclassing in O1. |
| O8 | `defaultPkCheck(imported(textField)) == valueError`. | SPEC E7 | Discharged constructively by O4 and the rejecting validation branch. |
| O9 | `defaultPkCheck(importError) == improperlyConfigured` and `defaultPkCheck(emptyPath) == improperlyConfigured`. | SPEC E8 | Discharged constructively by preserved non-validation branches. |
| O10 | `legacyExactTupleCheck(customBigAutoField) == false`. | SPEC E2, E3 | Discharged as the pre-fix defect witness, not as desired behavior. |
| O11 | The V1 source change preserves public API shape and existing `isinstance(..., AutoField)` behavior. | SPEC E5 and compatibility audit | Discharged by source inspection: no signature change and no edit to `__instancecheck__`. |

## K Claims

The obligations O1-O10 are encoded in `fvk/autofield-meta-spec.k`.
Obligation O11 is a source/API compatibility obligation recorded in
`fvk/SPEC.md`; it is not a K reachability claim because it concerns Python API
surface rather than the modeled boolean result.

## Expected Machine Check Commands

These commands are intentionally not run in this benchmark session:

```sh
kompile fvk/mini-python-autofield.k --backend haskell
kast --backend haskell fvk/autofield-meta-spec.k
kprove fvk/autofield-meta-spec.k
```

Expected result after a real machine check: `kprove` reduces the claims to
`#Top`.

## Residual Proof Caveat

The proof is constructed over a minimal semantics, not over full Python or full
Django. The abstraction is adequate for this issue because it preserves the
observable property under test: whether a class is accepted by
`issubclass(C, AutoField)` and then by `_get_default_pk_class()`.
