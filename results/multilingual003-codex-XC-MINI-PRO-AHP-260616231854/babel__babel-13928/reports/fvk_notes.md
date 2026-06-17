# FVK Notes

The FVK audit confirms V1 as V2 with no additional source edits.

Decision 1: keep the `parseFunctionBody` concise-branch exit added in V1.
Trace: F1 identifies the leaked concise-arrow-body `ExpressionScope` as the code bug. PO1 proves that the added `this.expressionScope.exit()` balances `newExpressionScope()` for concise bodies, and PO2 proves that this leaves the enclosing function-body scope on top before the later `await` or `yield`.

Decision 2: do not modify `recordParameterInitializerError`, `parseAwait`, or `parseYield`.
Trace: F2 states that actual parameter-initializer diagnostics must be preserved. PO3 discharges that preservation because V1 does not change the diagnostic logic, and PO4 confirms arrow-head validation remains unchanged.

Decision 3: do not refactor block-body parsing.
Trace: F3 states that block bodies were already balanced. PO5 confirms V1 adds cleanup only to the concise-body branch and leaves the block branch unchanged.

Decision 4: do not add defensive cleanup in `parseFunctionParams`.
Trace: F1 localizes the root cause to the missing concise-body exit, while PO2 relies on `parseFunctionParams` popping exactly the parameter scope after nested parsing is balanced. A defensive multi-pop would hide, rather than prove away, scope-stack imbalance.

Decision 5: do not run or edit tests.
Trace: F5 and PO6 record the task constraint that no execution environment exists and the hidden/fixed test suite must not be modified. The future test suggestions are recorded only in `fvk/ITERATION_GUIDANCE.md`.

Decision 6: label the proof honestly.
Trace: F4 and PO6 bound the proof to a targeted expression-scope model and mark the K artifacts as constructed, not machine-checked. This residual limitation does not justify further source edits because no additional code bug was found against the public intent.
