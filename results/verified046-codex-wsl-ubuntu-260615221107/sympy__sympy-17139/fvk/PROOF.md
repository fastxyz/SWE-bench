# Constructed Proof

Status: constructed, not machine-checked. No commands were executed.

## Claims Proved in the Model

The K claims in `fvk/tr56-spec.k` cover the decision points needed for the
audit:

- non-integer exponents return `unchanged`;
- negative and greater-than-`max` concrete integer exponents return unchanged;
- exponent `2` and `4` rewrite as documented;
- `pow=False` rewrites even concrete integer exponents and leaves odd ones
  unchanged;
- `pow=True` rewrites `8`, leaves `6` and `9` unchanged, and leaves symbolic
  integer exponents unchanged.

## Proof Sketch

There are no loops or recursion in the modeled `_TR56` decision fragment, so no
circularity is required. The proof is straight-line symbolic execution through
the ordered guards.

1. For a non-integer exponent, the first executable guard is
   `rv.exp.is_integer is not True`. It returns `rv`, so no ordered comparison or
   parity/perfect-power operation is reachable. This discharges F1 and PO-1.
2. For a concrete integer exponent, the non-integer guard is false. The proof
   splits on the negative and `> max` guards. Each true branch returns
   unchanged, discharging PO-2.
3. Remaining concrete integer exponents split on `2`, `4`, and the `pow` mode.
   The `2` and `4` branches produce the documented identity forms, discharging
   PO-3 and PO-4.
4. In the `pow=False` branch, the parity guard returns unchanged for odd
   exponents and rewrites even exponents with `exp//2`, discharging PO-5.
5. In the `pow=True` branch, V2 first requires a concrete integer exponent
   before `perfect_power`. The proof then splits on `perfect_power`'s abstracted
   result: base `2` rewrites, any other base or failure returns unchanged. This
   discharges PO-6 and addresses F2.

## Machine-Check Commands

These are the commands to run later in an execution-enabled environment:

```sh
kompile fvk/mini-sympy-fu.k --backend haskell
kast --backend haskell fvk/tr56-spec.k
kprove fvk/tr56-spec.k
```

Expected result after machine checking: `#Top` for all claims.

## Test Recommendation

No tests were modified. Existing public tests for `_TR56`, `TR5`, and `TR6`
exercise several in-domain examples and should be kept until the K claims are
machine-checked and the normal SymPy test suite can be run.

Additional tests to add when test editing is allowed:

- `simplify(cos(x)**I)` does not raise the reported `TypeError`;
- `_TR56(sin(x)**9, sin, cos, h, 10, True)` is unchanged;
- `_TR56(sin(x)**i, sin, cos, h, 10, True)` with symbolic integer `i` is
  unchanged rather than passing `i` to `perfect_power`.

## Residual Risk

The proof is partial and constructed only. It relies on the adequacy of the
small K model for the `_TR56` decision axis and on the abstraction that
`perfect_power(n)` with base `2` exactly represents "n is a power of two" for
the concrete exponents under audit.
