# FVK Iteration Guidance

Status: V1 stands unchanged.

## Code decision

Keep the V1 source change in `repo/packages/babel-generator/src/node/parentheses.ts`:

```ts
isUpdateExpression(parent, { argument: node, prefix: false })
```

Rationale:

- F-001 identifies the missing postfix update traversal as the root cause.
- PO-001 proves the concrete simplified reproduction now reaches the expression-statement context.
- PO-002 proves the general postfix update first-token step.
- PO-003 proves V1 avoids the over-broad alternative of treating prefix update as transparent.
- PO-004 and PO-007 show no unrelated behavior or public API surface is changed.

## Rejected changes

- Do not broaden the condition to all update expressions. PO-003 and F-002 show this would add behavior beyond the issue's first-token hazard.
- Do not move the new condition into `hasPostfixPart`. F-001 only requires `isFirstInContext` traversal, while `hasPostfixPart` is reused by other parenthesis rules with a broader meaning.
- Do not edit tests in this benchmark task. F-004 records the test gap, but the instructions forbid test modification.

## Future validation

When execution is available, run the project tests relevant to the generator, for example the normal Babel generator test target. When K tooling and an extracted K model are available, run:

```sh
kompile fvk/mini-babel-generator.k --backend haskell
kast --backend haskell fvk/generator-parentheses-spec.k
kprove fvk/generator-parentheses-spec.k
```

These commands were intentionally not run in this session.

## Test guidance for maintainers

Add a Babel generator parentheses fixture when tests may be edited:

```js
(function (){}).x++;
```

Expected output should keep parentheses around the function expression. Consider adjacent coverage for object/class expression roots under postfix update, because those use the same `isFirstInContext` helper.
