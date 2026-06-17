# FVK Spec

Status: constructed, not machine-checked. No tests, parser runs, Python, or K tooling were executed.

## Scope

This FVK pass models the parser state that determines the reported bug: the `ExpressionScopeHandler` stack around nested function parameters, arrow heads, arrow function bodies, and subsequent `await`/`yield` diagnostics. It does not attempt to formalize the full Babel parser or full JavaScript syntax. That narrower model is adequate for this issue because the public hint localizes the failure to expression-scope enter/exit balance.

Companion K core files:

- `fvk/mini-parser-scope.k`: a minimal stack-machine semantics for expression-scope operations.
- `fvk/parser-scope-spec.k`: K claims for the reported path, preservation of actual parameter errors, and branch balance.

Commands to machine-check later, intentionally not run here:

```sh
kompile fvk/mini-parser-scope.k --backend haskell
kast --backend haskell fvk/parser-scope-spec.k
kprove fvk/parser-scope-spec.k
```

## Public Intent Ledger

I1. Source: `benchmark/PROBLEM.md`.
Evidence: the two reported programs are described as valid, and the current diagnostics are described as incorrect.
Obligation: parsing a function body after a nested function containing `_=()=>null` must not raise the formal-parameter `await` or `yield` diagnostic for the following body expression.
Status: encoded by PO2 and `reported-await-yield-valid`.

I2. Source: public hint in `benchmark/PROBLEM.md`.
Evidence: the expected trace shows `enter ExpressionScope E2` for the concise arrow body, then `exit ExpressionScope E2`, then `exit ParameterDeclarationScope`, before the later `await null`.
Obligation: concise arrow-function bodies must balance their expression-scope entry before the enclosing parameter declaration exits.
Status: encoded by PO1 and `concise-arrow-body-balanced`.

I3. Source: `repo/packages/babel-parser/src/util/expression-scope.js`.
Evidence: `recordParameterInitializerError` returns when it reaches an `Expression` boundary, but raises if the current scope is a certain `ParameterDeclaration`.
Obligation: the subsequent `await`/`yield` is accepted exactly when the top visible scope is the enclosing function-body expression scope, not the nested parameter declaration scope.
Status: encoded by PO2 and PO3.

I4. Source: `repo/packages/babel-parser/src/parser/statement.js`.
Evidence: `parseFunctionParams` enters a `ParameterDeclaration` scope and exits one scope after parsing the binding list.
Obligation: nested parsing inside a parameter default must not leave an extra scope on top, or this exit can pop the wrong scope.
Status: encoded by PO1 and PO2.

I5. Source: `repo/packages/babel-parser/src/parser/expression.js`.
Evidence: `parseFunctionBody` enters `newExpressionScope()` for both concise expression bodies and block bodies. The block branch already exits it; V1 adds the same exit to the concise branch.
Obligation: both body forms must leave the expression-scope stack balanced.
Status: encoded by PO1 and PO5.

## Intended Contract

C1. For the reported path, starting with an enclosing function-body expression scope on top of the stack, parsing `function f(_=()=>null) {}` leaves that same enclosing expression scope on top before the following `await` or `yield`.

C2. When `recordParameterInitializerError` is called for the following `await` or `yield`, it sees an `Expression` boundary and does not raise the formal-parameter diagnostic.

C3. Actual formal-parameter errors are preserved: when `recordParameterInitializerError` is called while the top scope is still a `ParameterDeclaration` and no nested expression-scope boundary intervenes, it raises the existing diagnostic.

C4. Arrow-head validation behavior is preserved: `parseParenAndDistinguishExpression` still validates and exits the arrow-head scope before `parseArrowExpression`; V1 does not change that path.

C5. Block-bodied function parsing remains balanced and unchanged.

## Formal Model Summary

Scope stack top is the leftmost list item.

- `E` models a normal `ExpressionScope`.
- `P` models a `ParameterDeclaration` scope.
- `A` models an arrow-head scope.
- `recordParamInit` models the part of `recordParameterInitializerError` relevant to this bug: top `E` returns with `ok`; top `P` produces `paramError`.
- `parseConciseArrowBody` is `enter E; exit`, matching V1.
- `parseFunctionParamsWithConciseArrowDefault` is `enter P; parseArrowHead; parseConciseArrowBody; exit`.

The key claim is:

```k
parseFunctionParamsWithConciseArrowDefault ; recordParamInit
```

from an initial stack headed by `E` reaches a final stack still headed by `E` with outcome `ok`.
