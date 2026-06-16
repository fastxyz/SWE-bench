# FVK Findings

Status: findings are from static formalization and constructed proof only. No commands were run.

## F1 - Pre-V1 bug localized to Float zero shortcut

Input: `S(0.0) == S.false`

Observed pre-V1 path: `Float.__eq__` sympified `S.false`, then the zero-Float shortcut evaluated `not other`. Since `S.false` is falsey, the method returned `True`.

Expected: `False`, from issue evidence E1-E3 and public test evidence E4.

Classification: code bug, fixed by V1.

Proof obligation: PO1.

## F2 - V1 preserves the native `False` distinction better than the broader alternative

Input family: `Float(0.0) == False` versus `Float(0.0) == S.false`

Audit result: A broader edit that simply moved the post-sympification Boolean guard before the zero shortcut would also change native `False` after `_sympify(False)` becomes `S.false`. Public tests explicitly preserve `S(0) == False` while rejecting `S(0) == S.false`, so the narrower V1 shape is preferable.

Expected: already-SymPy Boolean atoms are rejected before sympification; native `False` remains on the existing sympify/zero path unless a separate issue changes that contract.

Classification: avoided compatibility regression.

Proof obligation: PO2.

## F3 - Reverse comparison already satisfies the intent

Input: `S.false == S(0.0)`

Observed source path: `S.false` is a `BooleanAtom`/`Basic` object and does not use `Float.__eq__` as the left-hand implementation. The issue reports this direction already returns `False`.

Expected: no source edit to `BooleanAtom.__eq__` or `Basic.__eq__` is needed.

Classification: confirmed existing behavior.

Proof obligation: PO4.

## F4 - Numeric Float equality frame is untouched

Input family: `Float` compared to other `Float`, `Rational`, `NumberSymbol`, and general `Number` operands.

Observed source path: V1 adds a guard before `_sympify`; the subsequent numeric branches are unchanged.

Expected: exact Float equality, Rational delegation, NumberSymbol delegation, and same-precision numeric comparison remain as before.

Classification: frame condition, no code change needed.

Proof obligation: PO3.

## F5 - Constructed proof is not machine-checked

Input: all proof obligations.

Observed: the FVK instructions forbid running `kompile`, `kprove`, Python, or tests in this task.

Expected: artifacts must label the proof "constructed, not machine-checked" and must not recommend deleting tests.

Classification: proof process limitation, not a code bug.

Proof obligation: PO6.

