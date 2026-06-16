# Proof Obligations

Status: constructed, not machine-checked.

| ID | Obligation | Evidence | Disposition |
| --- | --- | --- | --- |
| PO1 | Public intent supports immediate status-1 failure for an already-selected root containing `conf.py`. | E1, E3, E4 | Discharged by intent ledger and SPEC_AUDIT. |
| PO2 | `<root>/conf.py` branch reaches status 1, emits warning, does not generate, and does not prompt for a replacement root. | I1, I2, I4, I5 | Discharged by QS-EXISTING-ROOT. |
| PO3 | `<root>/source/conf.py` branch has the same status-1/no-generation behavior. | I3, E6 | Discharged by QS-EXISTING-SOURCE. |
| PO4 | The reported invalid-path loop cannot occur on the existing-project path. | E2, I4, I5 | Discharged by no `replacementPrompt` postcondition in QS-EXISTING-ROOT/SOURCE. |
| PO5 | `main()` returns the status from interactive `SystemExit(1)` and does not continue to `generate()`. | V1 diff, I6 | Discharged by the `exit(1) ~> _REST => .K` rule and both existing-project claims. |
| PO6 | Non-conflict paths are not altered by the existing-project guard change. | I6, E7 | Partially discharged as reduced frame claim QS-NO-CONF-FRAME; full questionnaire behavior remains outside this proof. |
| PO7 | Public API/callsite compatibility is preserved. | E8, callsite search | Discharged by PUBLIC_COMPATIBILITY_AUDIT. |
| PO8 | Machine-checking has not been run and tests must not be removed. | FVK honesty gate, task constraints | Recorded in PROOF and ITERATION_GUIDANCE. |

## Commands to machine-check later

Do not run these in this benchmark session. In a K-enabled environment:

```sh
cd fvk
kompile mini-python-quickstart.k --backend haskell
kast --backend haskell quickstart-spec.k
kprove quickstart-spec.k
```

Expected result after a successful machine check: `#Top` for all claims.
