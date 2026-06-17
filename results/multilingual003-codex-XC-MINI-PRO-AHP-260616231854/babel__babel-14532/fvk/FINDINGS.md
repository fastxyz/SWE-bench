# FVK Findings

Status: constructed, not machine-checked. Findings are derived from public issue text, source inspection, and proof construction. No tests or code were run.

## F-001: Pre-V1 postfix update dropped required function parentheses

- Classification: code bug, resolved by V1.
- Evidence: E-003 and E-004 in `fvk/SPEC.md`.
- Concrete input: `(function (){}).x++`.
- Pre-V1 observed behavior: `function (){}.x++`.
- Expected behavior: `(function () {}).x++` or equivalent output where the anonymous function expression is parenthesized.
- Cause: `isFirstInContext` walked from `FunctionExpression` through `MemberExpression`, then stopped at postfix `UpdateExpression`, so it returned false before reaching the `ExpressionStatement`.
- Proof obligations: PO-001 and PO-002.
- Resolution: V1 adds `isUpdateExpression(parent, { argument: node, prefix: false })` to the transparent-first branch.

## F-002: V1 correctly limits the new traversal to postfix updates

- Classification: confirmation / over-broadening guard.
- Evidence: E-007 and E-008 in `fvk/SPEC.md`.
- Concrete input class: `++(function (){}).x`.
- Expected behavior for the first-token contract: the function token is not first in the expression statement because the prefix operator is printed first.
- Audit result: V1 does not propagate through `UpdateExpression(prefix=true)`, so it avoids adding unnecessary parentheses for the reason this issue names.
- Proof obligations: PO-003 and PO-005.
- Resolution: no source change beyond V1.

## F-003: Full JavaScript grammar and full Babel printing are outside the constructed mini-model

- Classification: proof capability gap / residual risk.
- Evidence: FVK docs require labeling proofs constructed but not machine-checked; this task forbids running K tooling, tests, or project code.
- Concrete input: any broader generator case outside the modeled parent-stack transition relation.
- Observed vs expected: not evaluated in this session.
- Proof obligations: PO-006 and PO-008 identify the trusted base and command set.
- Resolution: keep tests; do not delete or mark tests redundant unless the emitted proof commands are later machine-checked.

## F-004: Regression tests are still needed but cannot be edited in this task

- Classification: test gap.
- Evidence: the public hint recommends adding a generator fixture under `packages/babel-generator/test/fixtures/parentheses`, while the benchmark forbids modifying tests.
- Concrete test shape: an input fixture containing `(function (){}).x++` and output retaining the function parentheses.
- Expected handling: add or keep such tests in normal project development; do not modify test files here.
- Proof obligations: PO-001 and PO-008.
- Resolution: documented in `fvk/ITERATION_GUIDANCE.md`; no test files changed.

## F-005: No public compatibility issue from V1

- Classification: compatibility confirmation.
- Evidence: `isFirstInContext` is private, exported parenthesis hooks keep signatures, and `isUpdateExpression` is an existing `@babel/types` validator.
- Concrete input: public callers of `@babel/generator` and internal calls to `FunctionExpression`, `ObjectExpression`, `ClassExpression`.
- Observed vs expected: the public API shape remains unchanged.
- Proof obligations: PO-004 and PO-007.
- Resolution: no source change needed.
