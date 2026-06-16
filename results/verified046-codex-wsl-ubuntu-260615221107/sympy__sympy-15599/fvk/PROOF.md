# FVK Proof

Status: constructed, not machine-checked. No `kompile`, `kast`, `kprove`,
Python, or tests were run.

## Claims Proved

The proof covers the V1 coefficient-normalization branch in
`repo/sympy/core/mod.py` lines 177-183.

For integers `C`, `Q`, and `T` with `Q != 0`, the branch may replace the
dividend `C*T` by `(C % Q)*T` inside `Mod(_, Q)` when the divisor is a plain
integer and `T` is known integer.

It also proves that the branch is not taken when the extracted coefficient is
not integer, the divisor has a remaining symbolic factor, or the tail is not
known integer.

## Arithmetic Proof for PO1

Use Python's modulo convention, also stated in the `Mod` docstring: the
remainder has the same sign as the divisor. For integer `C` and nonzero integer
`Q`, let:

```text
r = C % Q
n = floor(C / Q)
```

Then:

```text
C = Q*n + r
```

For any integer tail `T`:

```text
C*T = (Q*n + r)*T
    = Q*(n*T) + r*T
```

So `C*T` and `r*T` differ by a multiple of `Q`. Therefore they have the same
Python remainder modulo `Q`:

```text
Mod(C*T, Q) == Mod(r*T, Q)
```

This discharges PO1. The K helper claim is:

```k
claim
  <k> checkEquivalent(C:Int, T:Int, Q:Int) => true </k>
  requires Q =/=Int 0
  [all-path]
```

## Reported Instance for PO2

Set `C = 3`, `Q = 2`, and `T = i`.

```text
3 % 2 = 1
Mod(3*i, 2) == Mod((3 % 2)*i, 2)
            == Mod(i, 2)
```

The V1 code performs exactly this reconstruction: `p *= r` and `q *= cq`, so
the later final `cls(p, q, evaluate=(p, q) != (pwas, qwas))` rebuilds
`Mod(i, 2)` rather than `Mod(3*i, 2)`.

## Guard Proofs for PO3-PO5

The V1 branch condition is:

```python
cp.is_Integer and cq.is_Integer and q is S.One and p.is_integer
```

PO3: `Mod(e/2, 2)` exposes a rational numeric coefficient `1/2`, so
`cp.is_Integer` is false. The branch is not taken.

PO4: if the remaining tail is not known integer, `p.is_integer` is not true.
The branch is not taken.

PO5: if the divisor has a symbolic remaining factor after `q.as_coeff_Mul()`,
then `q is S.One` is false. The branch is not taken.

These guards are represented by the `unchanged` claims in
`fvk/sympy-mod-spec.k`.

## Compatibility Proof for PO6

The production diff changes only `repo/sympy/core/mod.py` inside
`Mod.eval`. It does not alter `Mod`'s public constructor signature, method
resolution, import surface, or test files. The return remains a SymPy
expression produced through the existing reconstruction path.

## Scope Limitation for PO7

The mini-K files model the coefficient-normalization branch and its guard
conditions. They do not model every branch of the full SymPy expression
system, including gcd extraction, denesting, `_eval_Mod` hooks, or float
normalization. The proof therefore justifies the V1 change against the issue
intent and public hint frame conditions; it is not a machine-checked proof of
all `Mod.eval` behavior.

## Machine-Check Commands

These commands are emitted for a future environment with K installed. They
were intentionally not executed here.

```sh
kompile fvk/mini-sympy-mod.k --backend haskell
kast --backend haskell fvk/sympy-mod-spec.k
kprove fvk/sympy-mod-spec.k
```

Expected result in a real K environment: all claims reduce to `#Top`.

## Test Guidance

No tests were modified. If the K proof is later machine-checked, point tests
inside the modeled domain, such as `Mod(3*i, 2) == Mod(i, 2)`, are subsumed by
PO1 and PO2. Tests for denominator, float, symbolic-divisor, integration, and
full `Mod.eval` behavior should be kept because they are outside the complete
machine-checked scope of this mini model.
