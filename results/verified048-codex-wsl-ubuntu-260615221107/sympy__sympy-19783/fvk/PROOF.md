# Constructed Proof

Status: constructed, not machine-checked.

## Claims

The formal claims are in `fvk/identity-dagger-spec.k`; the semantics fragment is
in `fvk/mini-sympy-quantum.k`.

## Proof Sketch

PO-DAGGER-RIGHT-ID:

1. Start with `<k> daggerMul(dagger(op(A)), idOp(N)) </k>`.
2. The first `daggerMul` rule matches because the left operand is exactly
   `dagger(op(A))` and the right operand is `idOp(N)`.
3. Rewrite result: `<k> dagger(op(A)) </k>`.
4. This is the claimed postcondition.

PO-DAGGER-LEFT-ID:

1. Start with `<k> identityMul(idOp(N), dagger(op(A))) </k>`.
2. The second `identityMul` rule matches because the right operand is
   `dagger(op(A))`.
3. Rewrite result: `<k> dagger(op(A)) </k>`.
4. This is the claimed postcondition.

PO-OP-RIGHT-ID and PO-OP-LEFT-ID:

1. The existing direct operator identity rules match `operatorMul(op(A), idOp(N))`
   and `identityMul(idOp(N), op(A))`.
2. Each rewrites to `op(A)`, preserving the existing public behavior.

PO-DAGGER-NONOP-FRAME and PO-NONOP-FRAME:

1. The operator-valued special-case patterns do not match `nonOp(X)`.
2. The `owise` generic multiplication rules apply.
3. The result keeps the identity factor in `mul(...)`, matching the non-operator
   frame condition.

## Verification Conditions

- The branches are mutually distinguished by expression shape:
  `op(A)` versus `nonOp(X)`, and `idOp(N)` versus any other expression.
- No arithmetic obligations are present.
- No loop circularities or termination measures are present.
- The proof is by finite symbolic execution and one rewrite per claim.

## Machine-Check Commands

These commands are required to upgrade this result from constructed to
machine-checked. They were not run.

```sh
kompile fvk/mini-sympy-quantum.k --backend haskell
kast --backend haskell fvk/identity-dagger-spec.k
kprove fvk/identity-dagger-spec.k
```

Expected machine-check outcome: `#Top` for all claims.

## Test Recommendation

Do not remove tests. If tests may be added in a normal development setting,
the direct issue cases worth adding are:

- `Dagger(Operator('A')) * IdentityOperator() == Dagger(Operator('A'))`
- `IdentityOperator() * Dagger(Operator('A')) == Dagger(Operator('A'))`
- a frame case showing a non-operator operand still produces generic `Mul`

Any test-removal recommendation is conditioned on actually running `kprove` and
getting `#Top`; this task forbids running the toolchain and modifying tests.
