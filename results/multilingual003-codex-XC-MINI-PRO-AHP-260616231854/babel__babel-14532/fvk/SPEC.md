# FVK Spec: babel__babel-14532

Status: constructed, not machine-checked. No tests, Babel code, Python, or K tooling were run.

## Scope

The audited production code is `repo/packages/babel-generator/src/node/parentheses.ts`, specifically the `isFirstInContext` helper used by `FunctionExpression`, `ObjectExpression`, `ClassExpression`, `DoExpression`, and `Identifier` parenthesis decisions.

This spec does not model the whole Babel generator. It models the observable property relevant to the issue: whether a printed child expression remains the first printed token in a syntactic context where a leading expression form must be protected by parentheses.

## Intent Spec

- IS-001: Babel output for valid input must not introduce JavaScript syntax that Node rejects with `SyntaxError: Function statements require a function name`.
- IS-002: The simplified public reproduction `(function (){}).x++` must retain parentheses around the function expression when printed as an expression statement.
- IS-003: The parenthesis decision for a function expression is based on whether the function expression is the "first thing in the expression".
- IS-004: A postfix update expression (`x++` or `x--`) prints its argument before the operator, so if its argument is a leftmost member/call chain rooted at a function expression, that function expression is still first in the outer expression.
- IS-005: Prefix update expressions print the operator first, so they are not part of this issue's "function token first" hazard.

## Public Evidence Ledger

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E-001 | prompt issue | "original code can be run by node correctly, but there is an error transformed by babel" | Generated code must preserve syntactic validity for this transform scenario. | Encoded by PO-001 and PO-002. |
| E-002 | prompt issue | `SyntaxError: Function statements require a function name` | Do not print an anonymous function expression where the statement grammar reads it as a function statement/declaration. | Encoded by PO-001. |
| E-003 | public hint | "A simpler reproduction is `(function (){}).x++`, without any transform, which is printed as `function (){}.x++`." | The concrete postfix update reproduction must print with protective function parentheses. | Encoded by PO-001. |
| E-004 | public hint | "That function should be wrapped in parentheses." | Required postcondition: `needsParens(FunctionExpression, ...)` is true for this stack shape. | Encoded by PO-001. |
| E-005 | public hint | "We print them when a function expression is the `first thing in the expression`" | `isFirstInContext` is the correct unit to model, and first-token propagation is the relevant property. | Encoded by PO-002. |
| E-006 | public hint | "It looks like it doesn't handle postfix unary operators (like `++`)." | Postfix update must be a transparent first-token parent when its `argument` is the current node. | Encoded by PO-002. |
| E-007 | implementation | `UpdateExpression` generator prints `node.argument` before `node.operator` when `node.prefix` is false. | The implementation transition for postfix update preserves first-token status through `UpdateExpression(argument=node, prefix=false)`. | Encoded by PO-002 and PO-005. |
| E-008 | implementation | `UpdateExpression` generator prints `node.operator` before `node.argument` when `node.prefix` is true. | Prefix update is not a transparent first-token parent for the child. | Encoded by PO-003. |
| E-009 | implementation | `isUpdateExpression` uses shallow option equality, including object identity for `argument` and boolean equality for `prefix`. | The V1 predicate precisely selects the current child and postfix updates. | Encoded by PO-005. |

Legacy output `function (){}.x++` is SUSPECT evidence: the issue identifies it as the defective output, so it is not used as an expected result.

## Formal Model

Definitions:

- `TargetContext(parent, node, options)` is true when one of the enabled context flags matches the current `(parent, node)` pair:
  - `expressionStatement` and `parent` is `ExpressionStatement(expression=node)`;
  - `exportDefault` and `parent` is `ExportDefaultDeclaration(declaration=node)`;
  - `arrowBody` and `parent` is `ArrowFunctionExpression(body=node)`;
  - `forHead`, `forInHead`, or `forOfHead` analogously match their existing Babel conditions.
- `TransparentFirst(node, parent)` is true when the parent's first printed token is the child's first printed token:
  - existing V1-preserved cases: member/optional member object, call/optional call callee, tagged template tag, TypeScript non-null child, first sequence expression, conditional test, binary left, and assignment left;
  - V1-added case: `parent` is `UpdateExpression(argument=node, prefix=false)`.
- `BlockedFirst(node, parent)` is true for parent shapes whose first printed token is not the child, including `UpdateExpression(argument=node, prefix=true)` and `NewExpression(callee=node)` inside `isFirstInContext`.

Function contract for `isFirstInContext(printStack, options)`:

1. Starting from the last node in `printStack`, walk parent pairs upward.
2. If `TargetContext(parent, node, options)` is reached, return `true`.
3. If `TransparentFirst(node, parent)` is true, continue with `node := parent`.
4. Otherwise return `false`.

The V1 source implements this model by adding:

```ts
isUpdateExpression(parent, { argument: node, prefix: false })
```

to the transparent-first branch.

## Formal Spec English

- C-001: For a print stack suffix `ExpressionStatement(UpdateExpression(prefix=false, argument=MemberExpression(object=FunctionExpression)))`, `FunctionExpression` requires parentheses.
- C-002: For any chain where each parent preserves the child's first printed token and the chain reaches an enabled target context, `isFirstInContext` returns true.
- C-003: A postfix `UpdateExpression` whose `argument` is the current node preserves the child's first printed token.
- C-004: A prefix `UpdateExpression` whose `argument` is the current node does not preserve the child's first printed token.
- C-005: Existing non-update transparent and blocking cases keep their V1 behavior except for the newly modeled postfix update step.

## Spec Audit

| Claim | Intent match | Result |
| --- | --- | --- |
| C-001 | Directly matches E-003 and E-004. | PASS |
| C-002 | Generalizes E-005 without relying on legacy output. | PASS |
| C-003 | Matches E-006 and implementation evidence E-007. | PASS |
| C-004 | Matches implementation evidence E-008 and prevents over-broadening beyond public intent. | PASS |
| C-005 | Preserves existing public behavior outside the named defect; no public evidence asks for broader changes. | PASS |

## Public Compatibility Audit

- Changed public API surface: none. `isFirstInContext` remains private to `parentheses.ts`.
- Changed exported functions: no signature changes. `FunctionExpression`, `ObjectExpression`, `ClassExpression`, and related exports keep the same parameters and return type.
- New dependency: none external. `isUpdateExpression` is imported from the existing `@babel/types` dependency already used throughout the file.
- Public callsites/overrides: no virtual dispatch or subclass protocol is changed.

Compatibility status: PASS.
