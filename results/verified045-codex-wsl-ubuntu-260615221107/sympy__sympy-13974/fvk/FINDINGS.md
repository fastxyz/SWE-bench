# FVK Findings

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## F-001: Original Pow Path Failed to Reach Component Simplification

Input: `tensor_product_simp(TensorProduct(1, Pauli(3))*TensorProduct(1, Pauli(3)))`

Observed before V1: the expression stayed as a power over the tensor product,
printed in the issue as `1xsigma3**2`.

Expected from public intent: `TensorProduct(1, 1)`, matching the workaround
`tensor_product_simp(TensorProduct(1, a)*TensorProduct(1, a)).subs(a, Pauli(3))`.

Classification: code bug in the `Pow` handling path.

V1 status: fixed by `tensor_product_simp_Pow` and
`TensorProduct._eval_expand_tensorproduct_pow`.

Trace: SPEC I-001, I-002; PROOF_OBLIGATIONS PO-001, PO-002, PO-005.

## F-002: `expand(tensorproduct=True)` Needed a `Pow` Dispatch Point

Input: `(TensorProduct(1, Pauli(3))*TensorProduct(1, Pauli(3))).expand(tensorproduct=True)`

Observed before V1: the expression stayed as a power over the tensor product,
printed in the issue as `1xsigma3**2`.

Expected from public intent: `TensorProduct(1, 1)`.

Classification: code bug in the expansion dispatch path.

V1 status: fixed by adding `Pow._eval_expand_tensorproduct`, gated on the base
advertising `_eval_expand_tensorproduct_pow`.

Trace: SPEC I-003, I-004; PROOF_OBLIGATIONS PO-003, PO-004, PO-006.

## F-003: Automatic `TensorProduct.__pow__` Evaluation Is Not Required

Input: constructing `TensorProduct(a, b)**n` without calling
`tensor_product_simp` or `expand(tensorproduct=True)`.

Observed in V1: construction remains governed by existing SymPy `Pow`
behavior unless an explicit simplification/expansion path is invoked.

Expected from public intent: the issue requires the named simplification and
expansion operations to work. The public hint names `tensor_product_simp_Pow`
and does not require a `TensorProduct._eval_power` change.

Classification: audited non-change; not a code bug.

V1 status: unchanged. This avoids broadening ordinary power construction beyond
the issue's explicit operations.

Trace: SPEC I-005; PROOF_OBLIGATIONS PO-007.

## F-004: Core `Pow` Compatibility Is Preserved by Hook Gating

Input: `Pow(B, E).expand(tensorproduct=True)` where `B` is not a
`TensorProduct` and does not implement `_eval_expand_tensorproduct_pow`.

Observed in V1: `Pow._eval_expand_tensorproduct` returns `self`.

Expected from public intent and compatibility: non-tensor powers must not
change under a tensor-product-specific expansion hint.

Classification: compatibility audit passed.

V1 status: unchanged.

Trace: SPEC I-004; PROOF_OBLIGATIONS PO-004, PO-006.

## F-005: Proof Is Constructed, Not Machine-Checked

Input: the FVK proof artifacts in this directory.

Observed: the proof is a static construction. The task forbids running Python,
tests, `kompile`, or `kprove`.

Expected: artifacts must state the exact obligations and expected proof result
without claiming machine-checked verification.

Classification: proof-process limitation, not a code bug.

V1 status: no code change. Existing and hidden tests must not be modified or
removed.

Trace: PROOF_OBLIGATIONS PO-008; PROOF "Machine-check commands".
