# FVK Proof

Status: constructed, not machine-checked. No test, Babel, Python, or K command was executed.

## What is proved

For the modeled parent-stack semantics of `isFirstInContext`, V1 proves:

1. A `FunctionExpression` rooted in a member/call chain that is the argument of a postfix `UpdateExpression` in an expression statement is classified as first in that expression statement.
2. The same first-token propagation holds for the general postfix update case.
3. Prefix update expressions remain non-transparent for this first-token purpose.
4. Existing non-update traversal behavior is unchanged.

## Concrete reproduction proof: PO-001

Let the print stack suffix be:

```text
[..., ExpressionStatement(E), UpdateExpression(U), MemberExpression(M), FunctionExpression(F)]
```

where:

```text
E.expression = U
U.prefix = false
U.argument = M
M.object = F
```

`isFirstInContext` starts with `node = F` and `parent = M`.

Step 1:

- `TargetContext(M, F)` is false.
- `hasPostfixPart(F, M)` is true because `M` is a member expression whose object is `F`.
- The loop advances to `node = M`, `parent = U`.

Step 2:

- `TargetContext(U, M)` is false.
- The existing postfix-part cases do not match `UpdateExpression`.
- The V1-added case `isUpdateExpression(U, { argument: M, prefix: false })` is true.
- The loop advances to `node = U`, `parent = E`.

Step 3:

- `TargetContext(E, U)` is true because the `expressionStatement` option is enabled and `E.expression === U`.
- The helper returns `true`.

By PO-006, `Printer.print` turns this true result into emitted parentheses around `F`. Thus the simplified reproduction is printed with the required protective function-expression parentheses.

## General postfix update proof: PO-002

The proof is by induction over the number of transparent parents between the dangerous child and the enabled target context.

Base case: if the immediate parent already satisfies `TargetContext(parent, node, options)`, the helper returns `true` before checking transparent parents.

Inductive step: assume every stack with `k` remaining transparent parents reaches the target context and returns `true`. For a stack with `k + 1` transparent parents:

- If the next parent is one of the existing transparent cases, V1 follows the pre-existing branch and reduces to the `k` case.
- If the next parent is `UpdateExpression(argument=node, prefix=false)`, V1 follows the added branch and reduces to the `k` case.

Therefore every postfix-update chain whose argument remains the first printed token reaches the same target context decision as the whole update expression.

## Prefix non-propagation proof: PO-003

For `UpdateExpression(argument=node, prefix=true)`:

- The V1-added predicate is false because `prefix: false` is required.
- The existing `hasPostfixPart` predicate does not classify `UpdateExpression` as a member/call/tag/non-null parent.
- The remaining transparent cases do not match merely because a node is the argument of a prefix update.

So `isFirstInContext` does not continue through prefix update due to V1. This matches the intent model because the prefix operator is printed before the child.

## Preservation proof: PO-004 and PO-007

The source diff adds one import and one disjunct in `isFirstInContext`. No exported function signature, public call protocol, or existing non-update condition is changed. For any input stack where the new disjunct is false, boolean evaluation of the traversal condition is identical to pre-V1 behavior.

## Residual risk and trusted base

- This is a constructed proof over a mini-model of the parent-stack helper, not a machine-checked proof over a full JavaScript or Babel semantics.
- The proof trusts that `Printer.print` continues to use `needsParens` as inspected and that `@babel/types` option matching stays shallow and exact as inspected.
- Termination is straightforward for the modeled helper because each traversal step decrements the stack index, but no formal total-correctness tool was run.

## Machine-check commands

These commands are recorded for a future extracted K model. They were not run:

```sh
kompile fvk/mini-babel-generator.k --backend haskell
kast --backend haskell fvk/generator-parentheses-spec.k
kprove fvk/generator-parentheses-spec.k
```

Expected outcome after a faithful extraction: `kprove` returns `#Top` for PO-001 through PO-003.

## Test recommendation

No tests are redundant from this constructed proof because it is not machine-checked and this task forbids modifying tests. A normal Babel contribution should keep existing generator tests and add a parentheses fixture for `(function (){}).x++`.
