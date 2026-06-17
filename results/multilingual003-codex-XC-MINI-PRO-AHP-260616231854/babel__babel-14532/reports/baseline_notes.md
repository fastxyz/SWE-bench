# Baseline Notes

## Root cause

`packages/babel-generator/src/node/parentheses.ts` decides whether a `FunctionExpression` needs parentheses by asking whether it is the first expression printed in contexts where a leading `function` token would be parsed as a declaration. The helper `isFirstInContext` already walks upward through member, call, sequence, conditional, binary, and assignment nodes when those parents preserve the current node as the leftmost printed expression.

For `(function (){}).x++`, the print stack reaches `FunctionExpression -> MemberExpression -> UpdateExpression -> ExpressionStatement`. The existing walk handled the `FunctionExpression -> MemberExpression` step, but then stopped at the postfix `UpdateExpression`. That made the generator think the function was not first in an expression statement, so it omitted the required parentheses and could print `function () {}.x++`, which starts an expression statement with an anonymous function and is invalid JavaScript.

## Changed files

- `repo/packages/babel-generator/src/node/parentheses.ts`: imported `isUpdateExpression` and taught `isFirstInContext` to keep walking through postfix update expressions when the current node is their argument. This preserves the "first printed token" relationship for postfix `++`/`--`, so function expressions in member chains remain parenthesized when needed.
- `reports/baseline_notes.md`: added this required implementation note.

## Assumptions and alternatives

- Assumption: the issue is specifically about postfix update expressions, because their argument is printed before the operator. Prefix updates print the operator first, so they do not put the function token first in the expression statement.
- Alternative considered: walk through all `UpdateExpression` nodes. I rejected that because it would also parenthesize prefix update operands where the first printed token is `++` or `--`, adding unnecessary parentheses outside the reported failure mode.
- Alternative considered: extend `hasPostfixPart` to include update expressions. I rejected that because `hasPostfixPart` is used in other parenthesis decisions where a postfix update expression is not generally the same as a member/call/tag chain; keeping the change inside `isFirstInContext` is narrower.

No tests or project code were run, in accordance with the task constraints.
