# Iteration Guidance

Status: V1 stands as V2. No additional source edits are recommended by this FVK pass.

## Decision

Keep the V1 code change unchanged: `parseFunctionBody` now exits the expression scope in the concise-arrow-body branch. Findings F1-F3 and proof obligations PO1-PO5 justify this as the minimal targeted repair.

## Do not change

- Do not change `recordParameterInitializerError`; F2 and PO3 show it is enforcing the correct diagnostic when the stack is accurate.
- Do not change `parseAwait` or `parseYield`; they correctly delegate the formal-parameter decision to the expression-scope handler.
- Do not add defensive multi-pop cleanup to `parseFunctionParams`; F1 localizes the imbalance to the missing concise-body exit, and defensive popping would hide future stack bugs.
- Do not edit tests in this task; F5 and PO6 reflect the fixed hidden-suite constraint.

## Suggested future tests

If test edits are allowed in a future task, add parser fixtures for:

- `(async function () { function f(_=()=>null) {} await null; });`
- `(function* () { function f(_=()=>null) {} yield; });`
- preservation cases where `await` or `yield` really appears in formal parameters and must still produce the existing diagnostics.

## Suggested future verification

Machine-check the constructed K core with:

```sh
kompile fvk/mini-parser-scope.k --backend haskell
kast --backend haskell fvk/parser-scope-spec.k
kprove fvk/parser-scope-spec.k
```

Expected result: `kprove` returns `#Top` for the targeted expression-scope claims. Until then, the proof remains constructed, not machine-checked.
