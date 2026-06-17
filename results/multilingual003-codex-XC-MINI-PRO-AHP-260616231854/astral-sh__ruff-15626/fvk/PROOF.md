# Constructed Proof

Status: constructed, not machine-checked. No commands were executed.

## Claims

The machine-checkable core is split across:

- `fvk/mini-fix-applicability.k`: a mini semantics for the applicability decision.
- `fvk/sim20-fix-spec.k`: reachability claims for safe, unsafe, NumPy-unknown, and initializer-precedence cases.

The commands to machine-check later are:

```sh
kompile fvk/mini-fix-applicability.k --backend haskell
kast --backend haskell fvk/sim20-fix-spec.k
kprove fvk/sim20-fix-spec.k
```

Expected machine result if the K fragment is accepted: `#Top`.

## Proof Sketch

PO-001 is a frame condition. The V2 diff does not change the guard checks for `UnaryOp::Not`, the single comparison operator match, the exception-check suppression, or the dunder-method suppression.

PO-005 is also a frame condition. The AST replacement construction remains the same as V1: SIM201 constructs a comparison node with `CmpOp::NotEq`; SIM202 constructs a comparison node with `CmpOp::Eq`; both replace `expr.range()`.

PO-002 follows by case split on operand evidence in `negated_comparison_fix_applicability`:

1. If `operand_eq_ne_returns_bool(left)` and `operand_eq_ne_returns_bool(right)` are both true, the function returns `Applicability::Safe`.
2. In every other boolean case, the function returns `Applicability::Unsafe`.

The mini K claims encode this same split as `known(left) and known(right)` versus its negation.

PO-003 follows from `expr_eq_ne_returns_bool`: a call expression is known only if `semantic.resolve_builtin_symbol` resolves its function to a whitelisted built-in constructor. A third-party attribute call such as `np.array(...)` does not meet that condition and is therefore `unknownCall` in the K abstraction. The unsafe claim discharges `fixApplicability(rule, unknownCall, unknownCall) => unsafe`.

PO-004 is the V2 improvement over V1. In `operand_eq_ne_returns_bool`, once a name resolves to a single binding, V2 first checks `typing::find_binding_value`. If a value exists, V2 returns the classification of that value immediately. Therefore an annotated assignment with an unknown initializer cannot fall through to `typing::is_int`, `typing::is_float`, or container helpers. In the K abstraction, `fixApplicability(rule, unknownCall, semanticKnown) => unsafe` records the left operand as decisive even if an annotation helper would otherwise report known.

PO-006 is a consequence of the unsafe branch. Any operand not classified by direct type inference, whitelisted built-in constructors, initializer evidence, or the remaining semantic helpers is unknown, and any unknown operand makes the combined predicate false. This may be conservative but cannot apply an unsafe automatic fix.

PO-007 is satisfied by labeling this proof constructed, not machine-checked, and by emitting the exact commands above.

## Test Guidance

No tests were run or modified. Because the proof is not machine-checked and hidden/public tests are fixed by the task, no test is recommended for removal. Useful tests to add outside this benchmark would cover:

- unknown names and `np.array(...)` bindings are unsafe for SIM201 and SIM202;
- annotated assignments with unknown initializers are unsafe;
- direct built-in literals and known built-in constructor results remain safe;
- replacement text remains unchanged.
