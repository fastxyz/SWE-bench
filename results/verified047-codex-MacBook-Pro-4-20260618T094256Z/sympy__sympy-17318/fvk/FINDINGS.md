# Findings

Status: constructed, not machine-checked.

## F1: V1 Removes The Reported `_sqrt_match` / `split_surds` Crash

Input: `_sqrt_match(4 + I)` as reached from
`sqrtdenest(3 - sqrt(2)*sqrt(4 + I) + 3*I)`.

Pre-V1 observed behavior: `_sqrt_match` treated `I` as acceptable because
`I**2` is rational, called `split_surds(4 + I)`, and `split_surds` called
`_split_gcd()` with no collected surds.

Expected behavior: no denesting match; the containing `sqrtdenest` expression is
left unchanged.

V1 audit result: pass. Claim C1 proves the shortcut is skipped for `4 + I`, and
claim C2 proves a direct `split_surds(4 + I)` call no longer reaches the empty
`_split_gcd` path.

Recommended code action: none.

## F2: V1 Handles Documented `rad_rationalize(1, 4 + I)` Gracefully

Input: `rad_rationalize(1, 4 + I)`.

Pre-V1 observed behavior from public issue: `IndexError`.

Expected behavior: no internal helper exception. Since there is no square-root
surd to remove, preserving `(1, 4 + I)` is the minimal no-op result.

V1 audit result: pass. Claim C3 reaches the no-op pair.

Recommended code action: none.

## F3: V1 Stops The Cube-Root Non-Progression Case

Input: `rad_rationalize(1, 1 + cbrt(2))`.

Pre-V1 observed behavior from public issue: infinite recursion.

Expected behavior: no recursive rationalization step when no square-root surd
was found.

V1 audit result: pass. Claim C4 reaches the unchanged pair without a recursive
edge.

Recommended code action: none.

## F4: Supported Square-Root Behavior Is Preserved

Inputs:

- `rad_rationalize(1, sqrt(2) + I)`
- documented `split_surds` regular-surd example

Expected behavior: V1's unsupported-input guards must not turn supported surd
inputs into no-ops.

V1 audit result: pass. Claim C5 preserves the mixed sqrt/complex rationalization
example, and claim C6 preserves the documented regular-surd grouping.

Recommended code action: none.

## F5: Proof Boundary, Not A Code Finding

The mini-semantics models the public issue examples and directly touched helper
branches. It does not model all SymPy expression canonicalization, all possible
complex radicals, or global termination of all denesting recursion.

Classification: proof capability / model-scope boundary.

Impact on revision decision: no concrete V1 counterexample or unmet public
proof obligation was found. Under the revision discipline, the correct action is
to keep V1 unchanged rather than broaden the patch speculatively.

## Proof-Derived Decision

No finding forces a code edit. V1 stands unchanged.
