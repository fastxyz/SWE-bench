# FVK Proof Obligations

Status: constructed, not machine-checked. These obligations are the proof core for the V1 audit.

## PO-001: Concrete simplified reproduction

Given a print stack suffix:

```text
ExpressionStatement(
  expression = UpdateExpression(
    prefix = false,
    argument = MemberExpression(
      object = FunctionExpression
    )
  )
)
```

when `FunctionExpression` calls `isFirstInContext(printStack, { expressionStatement: true, exportDefault: true })`, the function must return `true`.

Reason: E-003 and E-004 require the function expression in `(function (){}).x++` to be wrapped.

Status: discharged by the V1 update traversal.

## PO-002: General leftmost-token preservation through postfix update

For every current node `N` and parent `P`, if:

```text
P.type == "UpdateExpression"
P.argument === N
P.prefix === false
```

then `TransparentFirst(N, P)` holds for `isFirstInContext`.

Reason: E-006 and E-007 establish that postfix update prints the argument before the operator.

Status: discharged by `isUpdateExpression(parent, { argument: node, prefix: false })`.

## PO-003: Prefix update is not transparent for first-token propagation

For every current node `N` and parent `P`, if:

```text
P.type == "UpdateExpression"
P.argument === N
P.prefix === true
```

then the V1-added traversal case must not match.

Reason: E-008 establishes that prefix update prints the operator first, so the child expression is not first in the outer expression statement.

Status: discharged by the `prefix: false` predicate option.

## PO-004: Existing traversal behavior is preserved outside postfix update

For every stack pair not matching `UpdateExpression(argument=node, prefix=false)`, V1 must make the same continue/stop decision as the pre-V1 code.

Reason: the public issue identifies a missing postfix update case, not a broader rewrite of precedence or parenthesis policy.

Status: discharged syntactically: the only control-flow change in `isFirstInContext` is one added disjunct.

## PO-005: Validator exactness

The predicate `isUpdateExpression(parent, { argument: node, prefix: false })` must mean:

```text
parent is an UpdateExpression
parent.argument is the same object as node
parent.prefix is false
```

Reason: the proof relies on matching the current child, not any update expression in the stack.

Status: discharged by `@babel/types` generated validators delegating options to `shallowEqual`, which compares option keys with `!==`.

## PO-006: Integration with parentheses printing

If `FunctionExpression` receives `true` from `isFirstInContext`, then `Printer.print` must emit `(` before and `)` after the function expression.

Reason: the issue is about generated source syntax, not only the helper return value.

Status: discharged by `Printer.print`: `needsParens(...)` controls `if (shouldPrintParens) this.token("(")` and the matching closing token.

## PO-007: Public compatibility

V1 must not change the public API, exported hook signatures, or call protocol.

Reason: FVK compatibility audit requires changed public symbols and dispatch shapes to be checked.

Status: discharged by source inspection. V1 only imports `isUpdateExpression` and adds a private-helper branch.

## PO-008: Honesty and machine-checking boundary

The proof must be labeled constructed, not machine-checked, and test removal must remain conditional on future machine checking.

Reason: the task forbids running K tooling, tests, Python, or project code.

Status: discharged by `fvk/PROOF.md`, `fvk/FINDINGS.md`, and `fvk/ITERATION_GUIDANCE.md`.

## K-style Claims

These are the abstract claims the constructed proof reasons about:

```k
// CLAIM PO-001: concrete simplified reproduction
claim firstInContext(
  functionExpr,
  parents(memberObject, updatePostfixArgument, expressionStatement),
  options(expressionStatement: true, exportDefault: true)
) => true

// CLAIM PO-002: postfix update preserves first-token status
claim transparentFirst(N, updateExpression(argument: N, prefix: false)) => true

// CLAIM PO-003: prefix update does not preserve first-token status
claim transparentFirst(N, updateExpression(argument: N, prefix: true)) => false
```

Exact commands to machine-check an extracted K version later, not executed here:

```sh
kompile fvk/mini-babel-generator.k --backend haskell
kast --backend haskell fvk/generator-parentheses-spec.k
kprove fvk/generator-parentheses-spec.k
```
