# FVK Spec

Status: constructed, not machine-checked.

## Target

The audited code is the V1 patch in:

- `repo/sympy/physics/quantum/dagger.py`: `Dagger.__mul__`
- `repo/sympy/physics/quantum/operator.py`: `IdentityOperator.__mul__`

`Operator.__mul__` is included as a compatibility frame because the public issue
uses `A * IdentityOperator()` as the correct reference behavior.

## Public Intent Ledger

The ledger is mirrored in `fvk/PUBLIC_EVIDENCE_LEDGER.md`. The core obligations
are:

- `Dagger(Operator) * IdentityOperator()` returns `Dagger(Operator)`.
- `IdentityOperator() * Dagger(Operator)` returns `Dagger(Operator)`.
- Existing `Operator * IdentityOperator()` and
  `IdentityOperator() * Operator` behavior is preserved.
- Non-operator operands are not accidentally simplified by the quantum identity.

## Formal Model

The K-style model is in `fvk/mini-sympy-quantum.k`, with claims in
`fvk/identity-dagger-spec.k`.

The model intentionally covers only the observable property under audit:
expression-shape simplification for direct multiplication. It represents:

- `op(A)`: a quantum `Operator` instance;
- `idOp(N)`: an `IdentityOperator` instance, with dimension carried but not used
  by multiplication, matching the source behavior;
- `dagger(X)`: an unevaluated dagger expression;
- `nonOp(X)`: a non-operator expression;
- `mul(X, Y)`: generic unevaluated multiplication.

This abstraction distinguishes passing and failing cases for the defect:
`dagger(op(A))` and `mul(dagger(op(A)), idOp(N))` are different terms.

## Contracts

| ID | Contract | Provenance |
|---|---|---|
| PO-DAGGER-RIGHT-ID | `daggerMul(dagger(op(A)), idOp(N)) => dagger(op(A))` | E1, E2 |
| PO-DAGGER-LEFT-ID | `identityMul(idOp(N), dagger(op(A))) => dagger(op(A))` | E3 |
| PO-OP-RIGHT-ID | `operatorMul(op(A), idOp(N)) => op(A)` | E1, E4 |
| PO-OP-LEFT-ID | `identityMul(idOp(N), op(A)) => op(A)` | E3, E4 |
| PO-DAGGER-NONOP-FRAME | `daggerMul(dagger(nonOp(X)), idOp(N)) => mul(dagger(nonOp(X)), idOp(N))` | E5, E6 |
| PO-NONOP-FRAME | `identityMul(idOp(N), nonOp(X)) => mul(idOp(N), nonOp(X))` | E5 |

## Adequacy

`fvk/FORMAL_SPEC_ENGLISH.md` paraphrases each claim, and
`fvk/SPEC_AUDIT.md` compares the paraphrases against `fvk/INTENT_SPEC.md`.
All required obligations pass the adequacy audit. No required behavior is
candidate-derived only.

## Compatibility

No public signature changed. `Dagger.__mul__` is a new method that handles one
special case and delegates all other multiplication to `Expr.__mul__`.
`IdentityOperator.__mul__` keeps the existing `Operator` branch and adds a
specific `Dagger(Operator)` branch. Details are in
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
