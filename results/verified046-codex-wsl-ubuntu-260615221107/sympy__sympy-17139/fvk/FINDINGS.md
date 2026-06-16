# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 Correctly Removed the Reported Complex-Exponent Crash

Input: `simplify(cos(x)**I)` reaches `_TR56` through `TR6`.

V0 observed behavior: `_TR56` attempted `rv.exp < 0` with `rv.exp == I`, raising
`TypeError: Invalid comparison of complex I`.

Expected behavior: `_TR56` should not apply an even-integer trigonometric power
identity to a non-integer complex exponent. It should leave that power unchanged
for this rule and allow simplification to continue without this exception.

FVK result: V1's guard `if rv.exp.is_integer is not True: return rv` discharges
the reported crash path. This is retained in V2 and covered by PO-1.

## F2: V1 Left a `pow=True` Domain Gap in `_TR56`

Input A: `_TR56(sin(x)**i, sin, cos, h, max=10, pow=True)` where `i` is a
symbolic integer exponent.

V1 statically derived behavior: the top-level `is_integer` guard allows `i`
through, then the `pow=True` branch calls `perfect_power(i)`. `perfect_power`
requires a concrete integer via `as_int`, so this path is not justified for a
symbolic integer and can raise instead of leaving the expression unchanged.

Expected behavior: if `_TR56` cannot decide that a `pow=True` exponent is a
concrete power of two, it should leave the expression unchanged.

Input B: `_TR56(sin(x)**9, sin, cos, h, max=10, pow=True)`.

V1 statically derived behavior: `perfect_power(9)` succeeds even though `9` is
not a power of two. V1 would choose `e = 9//2` and rewrite an odd power as
`h(cos(x)**2)**4`, dropping one factor of `sin(x)`.

Expected behavior: the `_TR56` docstring and inline comment restrict `pow=True`
to exponents expressible as powers of two; `9` must remain unchanged.

FVK result: V2 adds a concrete-`Integer` guard before `perfect_power` and checks
that the perfect-power base is `2`. Covered by PO-6.

## F3: Machine Checking and Runtime Tests Remain Pending by Instruction

Input: the constructed K claims in `fvk/tr56-spec.k` and the SymPy test suite.

Observed process constraint: this task forbids running tests, Python, or K
tooling.

Expected verification process: run the emitted `kompile`/`kprove` commands and
the relevant SymPy tests in an environment where execution is allowed.

FVK result: no source change is blocked by this. The proof is labeled
"constructed, not machine-checked"; test removal is not recommended.
