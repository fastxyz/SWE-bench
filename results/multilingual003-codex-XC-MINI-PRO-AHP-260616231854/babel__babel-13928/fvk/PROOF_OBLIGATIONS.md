# Proof Obligations

Status: constructed, not machine-checked.

## PO1: Concise arrow expression bodies must balance `newExpressionScope()`

Evidence: `parseFunctionBody` enters an expression scope before the `isExpression` branch. V1 exits that scope after parsing and checking the concise body.

Obligation: for any stack `S`, parsing a concise arrow body maps `S` back to `S` with respect to expression-scope stack shape.

Discharge: `repo/packages/babel-parser/src/parser/expression.js` now has `this.expressionScope.exit()` in the concise-body branch after `node.body = this.parseMaybeAssign()` and `this.checkParams(...)`.

Linked findings: F1.

## PO2: The reported await/yield path must leave the enclosing body scope on top

Evidence: the public hint gives the intended trace: outer function body `E1`, nested function parameter `P`, arrow-head scope, arrow-body `E2`, exit `E2`, exit `P`, then parse the later `await`/`yield` in `E1`.

Obligation: starting with stack top `E`, parsing `function f(_=()=>null) {}` must return to stack top `E` before `recordParameterInitializerError` is called for the following `await` or `yield`.

Discharge: PO1 ensures the arrow-body `E2` is gone before `parseFunctionParams` exits. Therefore `parseFunctionParams` pops `P`, not `E2`, and the later diagnostic scan sees the outer `E`.

Linked findings: F1.

## PO3: Actual parameter-initializer diagnostics must be preserved

Evidence: `recordParameterInitializerError` intentionally raises on a current `ParameterDeclaration` scope.

Obligation: V1 must not cause real in-parameter `await` or `yield` errors to be swallowed.

Discharge: V1 does not modify `recordParameterInitializerError`, `parseAwait`, `parseYield`, `parseFunctionParams`, or arrow-head validation. If the top scope is still `P`, the existing code still raises.

Linked findings: F2.

## PO4: Arrow-head validation and error recording must remain unchanged

Evidence: `parseParenAndDistinguishExpression` validates and exits the arrow-head scope before calling `parseArrowExpression`.

Obligation: the fix must not bypass `validateAsPattern()` or alter when arrow-head errors are raised.

Discharge: V1 edits only the concise-body branch of `parseFunctionBody`, after arrow-head validation has already happened.

Linked findings: F2.

## PO5: Block-body cleanup must remain balanced and unchanged

Evidence: the non-expression branch of `parseFunctionBody` already calls `this.expressionScope.exit()` after parsing the block.

Obligation: the fix must not introduce a double exit or remove the existing block-body exit.

Discharge: V1 adds an exit only in the `isExpression` branch; the block branch remains unchanged.

Linked findings: F3.

## PO6: Residual risk must be honestly bounded

Evidence: this task forbids test execution and K execution, and the model is a targeted expression-scope abstraction rather than full JavaScript semantics.

Obligation: the proof must be labeled constructed, not machine-checked, and must not justify test removal or broad parser claims.

Discharge: `fvk/SPEC.md`, `fvk/PROOF.md`, and `fvk/ITERATION_GUIDANCE.md` record the commands and caveat. No tests were modified.

Linked findings: F4 and F5.
