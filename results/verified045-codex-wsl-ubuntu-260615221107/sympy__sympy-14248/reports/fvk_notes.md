# FVK Notes

## Decision

V1 stands unchanged. The FVK audit did not surface a source-code problem that
requires a V2 edit.

## Decision Trace

The root defect remains the one recorded as `F-001`: matrix-add printers joined
negative matrix terms as additive terms with visible negative bodies. V1 already
addresses this by using matrix-specific coefficient extraction and rendering
negative terms through subtraction. This is justified by `PO-SIGN`,
`PO-NO-PLUS-NEG`, `PO-NO-UNIT-COEFF`, and the per-printer loop obligations
`PO-STR`, `PO-LATEX`, and `PO-PRETTY`.

All issue-named printers are covered. `F-002` and `F-006` identify string,
pretty, and LaTeX matrix-add printing as the relevant contributors, and
`PO-COVERAGE` confirms that V1 edits each corresponding `_print_MatAdd`
implementation. No additional source file was needed.

I kept the internal matrix expression representation unchanged. `F-001` and
`F-003` treat the defect as display-only, while `PO-FRAME-REP` requires
`MatAdd`, `MatMul`, `MatrixExpr`, and `MatrixSymbol` construction to stay
unchanged.

I kept existing `expr.args` order. `F-003` records that public intent requires
subtraction-style signs but does not impose a new ordering rule, and
`PO-FRAME-ORDER` confirms V1 preserves the current order.

I kept the fallback for matrix-like objects without `as_coeff_mmul()`. `F-004`
classifies that path as a compatibility frame outside the MatrixSymbol
coefficient defect, and `PO-DOMAIN` plus `PO-FRAME-API` justify preserving
existing rendering for those objects.

I did not modify tests or run any commands. `F-005` records the proof honesty
caveat, and `PROOF.md` provides the `kompile`, `kast`, and `kprove` commands
without executing them.

## Artifacts Produced

The five requested FVK artifacts are complete:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK formal and adequacy core is also present under `fvk/`:

- `fvk/mini-python.k`
- `fvk/matrix-printing-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
