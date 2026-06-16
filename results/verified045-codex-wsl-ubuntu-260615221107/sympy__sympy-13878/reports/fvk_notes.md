# FVK Notes

## Source Decision

No production source file was changed during the FVK pass. This is justified by
`fvk/FINDINGS.md`:

- F-1 says the original integration fallback bug is closed by V1 because every
  named distribution now has a non-`None` `_cdf`, and PO-1 proves default `cdf`
  dispatch reaches those methods before integration.
- F-2 says the support metadata issue is closed by V1; PO-3 accounts for the
  corresponding support and endpoint branches.
- F-3 says the formula audit found no mismatch; PO-2 records the derivative
  obligations showing each in-support CDF branch matches the existing PDF.
- F-4 says the additive V1 changes preserve public API compatibility; PO-5
  records that constructor signatures, kwargs fallback behavior, and tests were
  not changed.

The remaining findings, F-5 and F-6, are proof/tooling and total-correctness
limitations. They do not justify a source edit because they do not identify a
wrong formula, missing distribution, dispatch regression, or compatibility
break.

## Artifact Decisions

- `fvk/SPEC.md` was added to record the public intent ledger and the CDF
  contract for the full distribution family named by the issue. This addresses
  the FVK intent-first requirement and supports PO-1 through PO-5.
- `fvk/FINDINGS.md` was added to classify the pre-V1 bug, the support metadata
  mismatch, the V1 closure, and the remaining non-source limitations. The V2
  no-op decision follows from F-1 through F-6.
- `fvk/PROOF_OBLIGATIONS.md` was added to make the proof checkable in pieces:
  dispatch, formula derivatives, support branches, Erlang-through-Gamma,
  compatibility, and the no-tooling honesty boundary.
- `fvk/PROOF.md` was added to give the constructed proof and adequacy check.
  It is explicitly labeled constructed, not machine-checked, tracing to F-5
  and PO-6.
- `fvk/ITERATION_GUIDANCE.md` was added to state that V1 stands, list future
  tests that would exercise the public examples, and map any future regression
  back to the relevant proof obligation.

## Execution Decision

No tests, Python imports, or K commands were run. This follows the task's
no-execution rule and is recorded in F-5 and PO-6. The K commands are written in
the proof artifacts as expected future machine-check commands only.
