# PROOF OBLIGATIONS

Status: constructed, not machine-checked. These obligations are encoded by `fvk/definition-state-spec.k`.

| ID | Obligation | Evidence | Encoded Claim | Status |
|---|---|---|---|---|
| PO-01 | In a type alias with no explicit type parameters, the alias assignment `=` must end `BeforeTypeParams`. | E-01, E-02, E-06 | `scanState(typeTok, nameTok, equalTok, nameTok, lsqbTok)` reaches `inTypeAlias(typeParamsEnded)`. | Discharged by construction |
| PO-02 | A right-hand-side `[` after the alias assignment must not make the alias value look like type parameters. | E-02, E-03 | Same claim as PO-01, plus issue-shaped E252 branch claim. | Discharged by construction |
| PO-03 | For the issue-shaped prefix before `min_length=...`, the `E252` missing-whitespace branch must be false. | E-01, E-03, E-06 | `isE252MissingBranch(scanState(issuePrefix), 2, false) => false`. | Discharged by construction |
| PO-04 | Actual type-parameter defaults must remain classified as type parameters. | E-05, E-06 | `isE252MissingBranch(scanState(typeTok, nameTok, lsqbTok, nameTok), 1, false) => true`. | Discharged by construction |
| PO-05 | Nested brackets inside type parameters must not prematurely end type-parameter state. | Implementation frame condition from `inner_square_brackets`. | Nested-bracket scan reaches `inTypeAlias(typeParamsEnded)` only after the outer `]`. | Discharged by construction |
| PO-06 | Annotated function parameter `E252` behavior must remain unchanged. | E-04 | `isE252MissingBranch(scanState(def ... colon ...), 1, true) => true`. | Discharged by construction |
| PO-07 | The fix must not require public API or test-suite changes. | E-07, task constraints | Compatibility audit shows only private state-machine behavior changes. | Discharged by source audit |

## Machine-Check Commands

Do not execute in this benchmark session. These are the commands to run in an environment with K installed:

```sh
kompile fvk/mini-ruff-logical-lines.k --backend haskell
kast --backend haskell fvk/definition-state-spec.k
kprove fvk/definition-state-spec.k
```

Expected result: `kprove` reduces the claims to `#Top`.
