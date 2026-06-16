# FVK Specification: TensorProduct Power Simplification

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Scope

The audited V1 change affects these production symbols:

- `TensorProduct._eval_expand_tensorproduct_pow`
- `tensor_product_simp_Pow`
- `tensor_product_simp` dispatch for `Pow`
- `Pow._eval_expand_tensorproduct`

The proof target is partial correctness of the symbolic rewrite rules used by
`tensor_product_simp` and `expand(tensorproduct=True)` for powers whose base is,
or simplifies to, a `TensorProduct`.

## Intent Specification

I-001: `tensor_product_simp(TensorProduct(a, b, c, ...)**n)` must return
`TensorProduct(a**n, b**n, c**n, ...)`.

I-002: If a product of tensor products has first simplified to a single
`TensorProduct`, a surrounding power must then be distributed to that resulting
tensor product's arguments.

I-003: `expand(tensorproduct=True)` must expose the same tensor-product power
distribution for a `Pow` whose base is a `TensorProduct`.

I-004: Non-target powers must preserve existing behavior. In particular, a
`Pow` whose base does not advertise tensor-product power expansion must remain
unchanged by the `tensorproduct` expansion hint.

I-005: The issue does not require default construction of
`TensorProduct(...)**n` to auto-evaluate without an explicit simplification or
expansion request. The required paths are `tensor_product_simp` and
`expand(tensorproduct=True)`.

## Public Evidence Ledger

E-001, source `prompt`: "Powers of tensor product expressions are not possible
to evaluate with either `expand(tensorproduct=True)` method nor the
`tensor_product_simp` function." Obligation: both named explicit operations
must handle tensor-product powers.

E-002, source `prompt`: `tps(tp(1,1)*tp(1,1))` and
`tp(1,1)*tp(1,1).expand(tensorproduct=True)` are shown as remaining
`1x1**2`; the workaround `tps(tp(1,1)*tp(1,a)).subs(a, 1)` yields `1x1`.
Obligation: the direct powered expression must simplify to the same result as
the substitution workaround.

E-003, source `prompt`: `tps(tp(1,Pauli(3))*tp(1,Pauli(3)))` and the matching
`expand(tensorproduct=True)` path are shown as remaining `1xsigma3**2`; the
workaround with `a = Pauli(3)` yields `1x1`. Obligation: component-level power
simplification must be reached so existing `Pauli(3)**2 -> 1` behavior can
apply.

E-004, source `prompt/hint`: "I would write a `tensor_product_simp_Pow` when
the argument is `Pow` ... take the exponent that is over the tensor product and
apply that to each argument in the tensor product." Obligation: implement the
component-wise rewrite for `Pow`.

E-005, source `source-docstring`: `TensorProduct._eval_expand_tensorproduct`
already distributes tensor products across addition under
`expand(tensorproduct=True)`. Obligation: preserve existing non-power expansion
behavior.

E-006, source `implementation`: SymPy's generic expansion mechanism dispatches
`_eval_expand_<hint>` on the expression being expanded. Obligation: `Pow` must
have a safe tensorproduct-hint dispatch path for `expand(tensorproduct=True)` to
affect `TensorProduct(...)**n`.

## Formal Domain

D-001: `E` ranges over SymPy expressions used as exponents.

D-002: `ARGS` is a non-empty finite sequence of SymPy expressions already held
as the arguments of a symbolic `TensorProduct`.

D-003: `simp_base(B)` denotes the result of recursively applying
`tensor_product_simp` to a power base `B`.

D-004: The verified rule is syntactic symbolic rewriting: distribute the
external exponent to each tensor-product argument and then let the ordinary
SymPy constructors simplify component powers such as `1**2` or
`Pauli(3)**2`.

## Formal English Claims

C-001: For any `TensorProduct` value `TP(ARGS)` and exponent `E`,
`_eval_expand_tensorproduct_pow(E)` returns `TP(map(lambda A: A**E, ARGS))`.

C-002: For any `Pow(B, E)`, if `tensor_product_simp(B)` is `TP(ARGS)`, then
`tensor_product_simp_Pow(Pow(B, E))` returns
`TP(map(lambda A: A**E, ARGS))`.

C-003: For any `Pow(B, E)`, if `tensor_product_simp(B)` is not a
`TensorProduct`, then `tensor_product_simp_Pow(Pow(B, E))` preserves the
previous recursive behavior by returning `tensor_product_simp(B)**E`.

C-004: `tensor_product_simp` dispatches `Pow` inputs to
`tensor_product_simp_Pow`, while preserving the previous `Add`, `Mul`,
`Commutator`, `AntiCommutator`, and fallback dispatches.

C-005: For any `Pow(B, E)`, `Pow._eval_expand_tensorproduct` delegates to
`B._eval_expand_tensorproduct_pow(E)` exactly when `B` advertises that hook;
otherwise it returns the original `Pow`.

C-006: Public signatures and return shape conventions are preserved:
`tensor_product_simp(e, **hints)` remains public, `tensor_product_simp_Pow` is
an internal helper, and no test files or public callsites are changed.

## Adequacy Audit

The formal claims match the intent entries:

- C-001 and C-002 encode I-001 and I-002 from E-004.
- C-004 preserves existing recursive simplification behavior while replacing
  the known weak `Pow` path.
- C-005 encodes I-003 and I-004 from E-001 and E-006.
- C-006 records the compatibility frame condition.

The audit rejects an automatic `TensorProduct._eval_power` obligation. The
issue examples show bare powered values as symptoms, but the stated failing
operations and the public hint both target explicit simplification/expansion
paths rather than default power construction.
