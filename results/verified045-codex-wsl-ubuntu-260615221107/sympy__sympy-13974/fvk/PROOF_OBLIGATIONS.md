# FVK Proof Obligations

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Abstract Mini-Semantics

The audited code is a structural symbolic rewrite over SymPy expression trees.
The mini-semantics models only the constructs used by the changed paths:

```k
module MINI-SYMPY-TENSORPRODUCT-SYNTAX
  syntax Expr ::= TP(ExprList)
                | Pow(Expr, Expr)
                | Add(ExprList)
                | Mul(ExprList)
                | Comm(Expr, Expr)
                | AntiComm(Expr, Expr)
                | Other(String)
  syntax ExprList ::= ".ExprList" | Expr "," ExprList
  syntax Bool ::= HasTPPowHook(Expr)
endmodule

module MINI-SYMPY-TENSORPRODUCT
  imports MINI-SYMPY-TENSORPRODUCT-SYNTAX

  syntax Expr ::= TPS(Expr)
                | TPSPow(Expr)
                | TPPow(Expr, Expr)
                | ExpandTPPow(Expr)
                | PowEach(ExprList, Expr)

  // TPPow is TensorProduct._eval_expand_tensorproduct_pow.
  rule TPPow(TP(ARGS), E) => TP(PowEach(ARGS, E))

  // TPSPow is tensor_product_simp_Pow over a Pow input.
  rule TPSPow(Pow(B, E)) => TPPow(TPS(B), E)
    requires isTP(TPS(B))
  rule TPSPow(Pow(B, E)) => Pow(TPS(B), E)
    requires notBool isTP(TPS(B))

  // TPS dispatches the public tensor_product_simp cases relevant here.
  rule TPS(Pow(B, E)) => TPSPow(Pow(B, E))
  rule TPS(Add(ARGS)) => Add(MapTPS(ARGS))
  rule TPS(Mul(ARGS)) => TPSMul(Mul(ARGS))
  rule TPS(Comm(L, R)) => Comm(TPS(L), TPS(R))
  rule TPS(AntiComm(L, R)) => AntiComm(TPS(L), TPS(R))
  rule TPS(X) => X [owise]

  // ExpandTPPow is Pow._eval_expand_tensorproduct.
  rule ExpandTPPow(Pow(B, E)) => TPPow(B, E)
    requires HasTPPowHook(B)
  rule ExpandTPPow(Pow(B, E)) => Pow(B, E)
    requires notBool HasTPPowHook(B)
endmodule
```

These modules are an abstract proof model for the changed rewrite paths, not a
full Python or full SymPy semantics.

## Obligations

PO-001: Component-wise tensor-product power distribution.

Claim: for any finite `ARGS` and exponent `E`,
`TPPow(TP(ARGS), E)` rewrites to `TP(PowEach(ARGS, E))`.

Proven by: direct application of the V1 implementation
`TensorProduct._eval_expand_tensorproduct_pow`, whose body constructs
`TensorProduct(*[arg**exp for arg in self.args])`.

Findings trace: F-001.

PO-002: `tensor_product_simp_Pow` distributes powers when the simplified base
is a `TensorProduct`.

Claim: for any `B`, `E`, and `ARGS`, if `TPS(B) = TP(ARGS)`, then
`TPSPow(Pow(B, E)) => TP(PowEach(ARGS, E))`.

Proven by: symbolic execution through `base = tensor_product_simp(e.base)`,
the `isinstance(base, TensorProduct)` branch, and PO-001.

Findings trace: F-001.

PO-003: `tensor_product_simp_Pow` preserves previous behavior when the
simplified base is not a `TensorProduct`.

Claim: if `TPS(B)` is not a `TensorProduct`, then
`TPSPow(Pow(B, E)) => Pow(TPS(B), E)`.

Proven by: symbolic execution through the `else: return base**e.exp` branch.

Findings trace: F-004.

PO-004: `Pow._eval_expand_tensorproduct` delegates only to bases that advertise
tensor-product power expansion.

Claim: if `HasTPPowHook(B)` then
`ExpandTPPow(Pow(B, E)) => TPPow(B, E)`; otherwise
`ExpandTPPow(Pow(B, E)) => Pow(B, E)`.

Proven by: the `hasattr(self.base, '_eval_expand_tensorproduct_pow')` branch in
`Pow._eval_expand_tensorproduct`.

Findings trace: F-002, F-004.

PO-005: The issue's identity tensor example is discharged.

Claim: `TPSPow(Pow(TP(1, 1), 2)) => TP(1, 1)`.

Derivation: PO-002 reduces the expression to `TP(1**2, 1**2)`. Ordinary SymPy
power simplification for `1**2` yields `1`, so the result is `TP(1, 1)`.

Findings trace: F-001.

PO-006: The issue's Pauli example is discharged.

Claim: `TPSPow(Pow(TP(1, Pauli(3)), 2)) => TP(1, 1)`.

Derivation: PO-002 reduces the expression to `TP(1**2, Pauli(3)**2)`. The
existing `Pauli._eval_power` rule for positive integer powers reduces
`Pauli(3)**2` to `1`, so the result is `TP(1, 1)`.

Findings trace: F-001, F-002.

PO-007: No automatic construction-path power evaluation is required.

Claim: the proof obligations cover `tensor_product_simp` and
`expand(tensorproduct=True)` paths only. They do not require adding
`TensorProduct._eval_power`.

Justification: SPEC I-005 and FINDINGS F-003.

PO-008: Machine-check honesty condition.

Claim: this proof remains "constructed, not machine-checked" until the
following commands are run in an environment with K tooling:

```sh
kompile fvk/mini-sympy-tensorproduct.k --backend haskell
kast --backend haskell fvk/tensorproduct-power-spec.k
kprove fvk/tensorproduct-power-spec.k
```

Expected machine-check result after writing the embedded mini-semantics and
claims to those files: `#Top`.
