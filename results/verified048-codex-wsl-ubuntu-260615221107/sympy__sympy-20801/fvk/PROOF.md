# Constructed Proof

Status: constructed, not machine-checked. No tests, Python, `kompile`, `kast`, or `kprove` were run.

## Summary

The V1 fix satisfies the intent contract: an operand that is already a SymPy `Boolean` is rejected before `_sympify` and before the zero-Float truthiness shortcut. Therefore `S(0.0) == S.false` reaches `False`, matching `S.false == S(0.0)` and the integer-zero examples from the issue.

## Pre-V1 Failure Trace

For `Float.__eq__(Float(0.0), S.false)` before V1:

1. `_sympify(S.false)` returns `S.false`.
2. `not self` is true because the Float is zero.
3. The method returns `not other`.
4. `not S.false` is true.

This constructs the reported bad result: `S(0.0) == S.false` returns `True`.

## V1 Proof Trace for PO1

For `Float.__eq__(F, B)` where `B` is already an instance of SymPy `Boolean`:

1. Enter `Float.__eq__`.
2. Import `Boolean`.
3. Evaluate `isinstance(B, Boolean)`.
4. The predicate is true by PO1's precondition.
5. Return `False`.

The proof does not depend on whether `F` is zero, so it covers both `S(0.0) == S.false` and nonzero Float/Boolean comparisons.

## V1 Proof Trace for PO2

For `Float.__eq__(Float(0.0), False)`:

1. Native `False` is not an instance of SymPy `Boolean` before sympification.
2. The early V1 guard does not fire.
3. Control reaches the original `_sympify` and zero-Float branch.

Thus V1 does not implement the broader "all Python bools are SymPy Booleans before the zero branch" change rejected in Finding F2.

## V1 Proof Trace for PO3 and PO5

For any operand that is not already a SymPy `Boolean`, V1 proceeds to the same code sequence as pre-V1:

1. `_sympify(other)` is attempted.
2. `SympifyError` still returns `NotImplemented`.
3. A zero Float still uses the existing `return not other` shortcut.
4. Nonzero Float comparisons still flow through the unchanged `NumberSymbol`, `Float`, `Rational`, `Number`, and final non-Number branches.

No numeric branch is edited, so the frame obligations hold by syntactic preservation of the source path.

## V1 Proof Trace for PO4

The reverse comparison `S.false == S(0.0)` does not call the edited `Float.__eq__` as the left-hand implementation. V1 does not edit `BooleanAtom`, `Boolean`, or `Basic`, so the reported reverse result remains `False`.

## Adequacy Gate

The English formal claim is: "already-SymPy Boolean operands compare unequal to Float values before any zero-Float truthiness shortcut can run." This matches E1-E4 and does not rely on candidate behavior as the specification.

The native-`False` frame is justified by E5 and by the issue's explicit use of `S.false`. It prevents the proof from overfitting the bug by changing a broader class of public comparisons.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They were not run here.

```sh
cd fvk
kompile mini-sympy-eq.k --backend haskell
kast --backend haskell float-eq-spec.k
kprove float-eq-spec.k
```

Expected outcome if the miniature semantics is accepted: `kprove` reduces the claims to `#Top`.

## Test Guidance

No tests were run and no test files were modified. If tests were editable in a normal development setting, the useful regression assertions would be:

```python
assert S(0.0) != S.false
assert S.false != S(0.0)
assert Float(0.0) != false
```

Existing tests for `S(0) == False` and `S(0) != S.false` should be kept; the constructed proof is not machine-checked and the task forbids test edits.
