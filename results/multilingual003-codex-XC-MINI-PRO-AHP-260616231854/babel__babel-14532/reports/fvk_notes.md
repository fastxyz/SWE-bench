# FVK Notes

## Decision summary

V1 stands unchanged. The audit found the original missing case and confirmed that the V1 edit is the narrow repair required by the public issue.

## Trace to findings and proof obligations

- Kept the V1 `isUpdateExpression(parent, { argument: node, prefix: false })` branch because F-001 identifies the pre-V1 bug as failure to traverse through postfix update, and PO-001 proves the simplified reproduction reaches the expression-statement context after the edit.
- Treated the repair as general for postfix updates because PO-002 proves first-token preservation for any `UpdateExpression` whose `argument` is the current node and whose `prefix` is false.
- Did not broaden the condition to all update expressions because F-002 and PO-003 show prefix updates print the operator first, so they are outside the issue's first-token hazard.
- Did not move the logic into `hasPostfixPart` because F-001 only requires `isFirstInContext` to recognize postfix update as a transparent parent, while `hasPostfixPart` feeds other parenthesis rules with a broader meaning. This is also covered by PO-004's preservation obligation.
- Made no public compatibility edits because F-005 and PO-007 show the change is private to generator parenthesis logic and does not alter exported hook signatures or public API shape.
- Did not add or modify tests because F-004 records the needed fixture but the benchmark forbids test edits.
- Did not run tests or formal tooling because F-003 and PO-008 record the constructed, not machine-checked boundary required by the task.

## Files changed in this FVK pass

- `fvk/SPEC.md`: intent ledger, formal model, adequacy audit, and compatibility audit.
- `fvk/FINDINGS.md`: resolved bug finding, confirmation findings, residual proof/tooling risk, and test gap.
- `fvk/PROOF_OBLIGATIONS.md`: proof obligations PO-001 through PO-008 and K-style abstract claims.
- `fvk/PROOF.md`: constructed proof for the concrete reproduction, general postfix update case, prefix non-propagation, and preservation.
- `fvk/ITERATION_GUIDANCE.md`: code decision, rejected changes, and future test/tool guidance.
- `reports/fvk_notes.md`: this traceability note.

No production source files changed during the FVK pass.
