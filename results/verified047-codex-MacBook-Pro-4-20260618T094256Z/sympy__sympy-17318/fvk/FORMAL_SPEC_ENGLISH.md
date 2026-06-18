# Formal Spec, English Paraphrase

Status: constructed, not machine-checked.

## Claims

C1. `_sqrt_match(4 + I)` reaches `noMatch`.

Paraphrase: because `I**2` is rational but non-positive, the expression is not a
regular non-complex square-root surd sum. The helper must not call `split_surds`
and must report no match.

C2. `split_surds(4 + I)` reaches `split(1, 0, 4 + I)`.

Paraphrase: an additive expression with no supported explicit square-root term
returns a well-formed no-surd split result. `_split_gcd` is not reached.

C3. `rad_rationalize(1, 4 + I)` reaches `(1, 4 + I)`.

Paraphrase: since there is no square-root component to remove, the documented
helper returns the original numerator and denominator rather than raising.

C4. `rad_rationalize(1, 1 + cbrt(2))` reaches `(1, 1 + cbrt(2))`.

Paraphrase: a cube-root denominator is unsupported by the square-root
rationalizer, so the function stops without a recursive call.

C5. `rad_rationalize(1, sqrt(2) + I)` reaches `(sqrt(2) - I, 3)`.

Paraphrase: the V1 guard for unsupported no-surd inputs does not disable the
existing supported mixed sqrt/complex rationalization path.

C6. The documented `split_surds` regular-surd example reaches the documented
grouping.

Paraphrase: V1 keeps the ordinary positive real-surd grouping behavior that the
docstring advertises.

## Frame Conditions

F1. No helper signature changes.

F2. Return shapes are unchanged: `_sqrt_match` returns a match list or no-match
sentinel, `split_surds` returns a 3-tuple, and `rad_rationalize` returns a pair.

F3. The proof is partial correctness only and is constructed, not
machine-checked.

## Side Conditions

S1. `split_surds` may call `_split_gcd` only when at least one explicit
square-root surd was collected.

S2. `_sqrt_match` may use the regular-surd shortcut only when every addend
square is rational and positive.

S3. `rad_rationalize` recursion requires progress: the denominator must have a
square-root component that can be moved out by `split_surds`.
