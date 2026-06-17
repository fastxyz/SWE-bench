# Baseline Notes

## Root cause

`parseFunctionBody` enters a fresh `ExpressionScope` before parsing every function body. For block bodies, that scope was exited after parsing the block. For concise arrow-function expression bodies, the scope was not exited.

When a concise arrow appeared inside a default parameter initializer, for example `function f(_ = () => null) {}`, the leaked arrow-body expression scope stayed on top of the expression-scope stack. The surrounding function-parameter cleanup then popped that leaked scope instead of popping the `ParameterDeclaration` scope for `f`'s parameters. That left the parser thinking it was still inside formal parameters while it later parsed `await` or `yield` in the enclosing function body, so the existing parameter-initializer diagnostics were raised incorrectly.

## Changed files

- `repo/packages/babel-parser/src/parser/expression.js`: added the missing `this.expressionScope.exit()` after parsing and checking a concise arrow-function expression body. This balances the `newExpressionScope()` entry in the `isExpression` branch, matching the block-body branch.

## Assumptions and rejected alternatives

- I assumed the problem is a scope-stack cleanup bug rather than an issue with `parseAwait`, `parseYield`, or `recordParameterInitializerError`. Those routines intentionally record or raise errors based on the current expression-scope stack; the stack was wrong after parsing the nested arrow.
- I considered changing `parseFunctionParams` to defensively pop until the parameter scope was gone, but rejected it because that would hide the actual leak and could mask other parser-state imbalances.
- I considered special-casing `await` and `yield` following function declarations, but rejected it because the same stale `ParameterDeclaration` scope can affect any later parse in the enclosing body. Balancing the arrow-body expression scope fixes the underlying state.
