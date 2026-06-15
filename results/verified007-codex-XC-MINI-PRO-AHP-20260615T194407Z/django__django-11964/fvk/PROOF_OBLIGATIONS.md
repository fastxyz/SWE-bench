# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Formal claim / artifact | Status |
| --- | --- | --- | --- |
| PO1 | Public intent must be captured without preserving the reported legacy bug. | `INTENT_SPEC.md`, `SPEC_AUDIT.md` | Discharged by adequacy audit. |
| PO2 | Created enum-member field values stringify to the concrete value text for all modeled `TextChoices`/`IntegerChoices` values. | `CREATED-CHOICE-STR` in `choices-str-spec.k` | Constructed proof in `PROOF.md`. |
| PO3 | Retrieved primitive field values stringify to the same concrete value text. | `RETRIEVED-PRIMITIVE-STR` in `choices-str-spec.k` | Constructed proof in `PROOF.md`. |
| PO4 | Created and retrieved paths have the same string-rendered external output. | `CREATED-RETRIEVED-EQUIVALENCE` in `choices-str-spec.k` | Constructed by transitivity from PO2 and PO3. |
| PO5 | The public example reaches `"first"` on the creation path. | `CREATED-TEXTCHOICES-EXAMPLE` in `choices-str-spec.k` | Constructed by specializing PO2 with `V = SVal("first")`. |
| PO6 | Enum metadata and `repr()` behavior are preserved. | `REPR-FRAME`, public compatibility audit | Discharged by frame reasoning: V1 only defines `__str__`. |
| PO7 | The base-class placement does not break public callsites or documented APIs. | `PUBLIC_COMPATIBILITY_AUDIT.md` | Discharged by source/docs/test audit; residual custom-subclass behavior noted in F4. |
| PO8 | The fix does not require modifying tests or running code. | Task constraints, `FINDINGS.md` | Discharged; no tests were edited or run. |

## Commands To Machine-Check Later

These commands are emitted for a future environment with K installed. They were not run in this task.

```sh
cd fvk
kompile mini-python-enum.k --backend haskell
kast --backend haskell choices-str-spec.k
kprove choices-str-spec.k
```

Expected machine-check result if the mini semantics and claims are accepted: `#Top`.
