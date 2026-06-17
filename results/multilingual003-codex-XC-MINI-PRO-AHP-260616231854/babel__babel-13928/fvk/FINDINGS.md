# FVK Findings

Status: constructed, not machine-checked. Findings are from public intent, static source inspection, and the constructed FVK model only.

## F1: Resolved code bug - concise arrow body leaked an expression scope

Input: `(async function () { function f(_=()=>null) {} await null; });` and `(function* () { function f(_=()=>null) {} yield; });`

Observed before V1: the issue reports `SyntaxError: 'await' is not allowed in async function parameters.` and `Yield expression is not allowed in formal parameters.`

Expected: both programs are valid and the later `await`/`yield` belongs to the enclosing function body, not to `f`'s formal parameters.

Cause: before V1, the concise-body branch of `parseFunctionBody` entered `newExpressionScope()` but did not exit it. Then `parseFunctionParams` popped that leaked `Expression` scope instead of the `ParameterDeclaration` scope, leaving `P` on top for the later `await`/`yield`.

Resolution: V1 adds `this.expressionScope.exit()` to the concise-body branch. This discharges PO1 and PO2. No further source change is required.

## F2: Preserved behavior - actual parameter-initializer errors must still throw

Input class: actual `await` or `yield` parsed while the current expression-scope top is a `ParameterDeclaration` scope, with no nested function-body `Expression` boundary in between.

Observed in code: `recordParameterInitializerError` raises when the scan reaches a certain parameter declaration.

Expected: Babel must continue rejecting real formal-parameter `await`/`yield` violations.

Resolution: V1 changes only the stack cleanup for concise arrow bodies. It does not alter `recordParameterInitializerError`, `parseAwait`, `parseYield`, or arrow-head validation. This discharges PO3.

## F3: Confirmed unchanged branch - block bodies were already balanced

Input class: nested arrows or functions whose bodies are block bodies rather than concise expression bodies.

Observed in code: the block-body branch of `parseFunctionBody` already exits the expression scope after parsing the block.

Expected: V1 must not disturb this existing balance.

Resolution: V1 leaves the block-body branch unchanged, while adding the missing symmetric cleanup only to the concise-body branch. This discharges PO5.

## F4: Formalization limitation - full parser not machine-checked

Input class: any parser behavior outside the expression-scope stack discipline modeled here.

Observed: the FVK model abstracts away tokenization, AST construction, Flow/TypeScript plugins, and the full arrow-head error map.

Expected: this audit can justify the targeted fix, but it is not a machine-checked proof of the entire Babel parser.

Resolution: no code change follows from this limitation. The K commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md` for later machine checking. This is linked to PO6 as residual risk.

## F5: Test guidance only - fixed hidden suite must not be edited here

Input class: regression tests for the two reported examples and preservation tests for real parameter errors.

Observed: the task forbids modifying tests and forbids running tests.

Expected: production code and FVK artifacts only.

Resolution: no test files were changed or run. Suggested future tests are recorded in `fvk/ITERATION_GUIDANCE.md`.
