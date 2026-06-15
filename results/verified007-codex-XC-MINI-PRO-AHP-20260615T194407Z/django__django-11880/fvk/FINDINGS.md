# FVK Findings

Constructed, not machine-checked.

## F-001: Original aliasing bug is resolved by V1

Classification: code bug, resolved.

Input shape: a declared form field copied into two form instances, or a field
object copied twice with `copy.deepcopy()`.

Observed before V1: copied fields shared the same `error_messages` dictionary
because `Field.__deepcopy__()` used `copy.copy(self)` and did not replace the
`error_messages` attribute.

Expected from public intent: each copied field has an isolated
`error_messages` mapping.

Evidence: ledger entries E1, E2, E4.

Proof obligation: PO-1 and PO-4.

V1 status: satisfied by `result.error_messages =
copy.deepcopy(self.error_messages, memo)`.

## F-002: Shallow dictionary copy is insufficient

Classification: rejected alternative.

Input shape: `error_messages` contains a nested mutable message value supplied
by user code.

Observed with a shallow `dict.copy()` alternative: top-level dictionary mutation
would be isolated, but mutation of the nested value could still leak between
field copies.

Expected from public intent: modification of "the error message itself" must not
leak between copied fields.

Evidence: ledger entry E3.

Proof obligation: PO-2.

V1 status: satisfied by using `copy.deepcopy()`, not `dict.copy()`.

## F-003: No public compatibility regression found

Classification: compatibility audit result.

Input shape: public callers and subclass `__deepcopy__()` implementations that
invoke the base field deepcopy protocol.

Observed in V1: the method signature and surrounding widget/validator copy
behavior are unchanged.

Expected from public intent: fix the aliasing bug without changing the public
deepcopy protocol or unrelated behavior.

Evidence: ledger entries E5, E6, E7.

Proof obligation: PO-3, PO-4, PO-5.

V1 status: no additional code change justified.

## Proof-derived findings from `/verify`

No proof-derived code bug was found in V1. The proof obligations cover the full
reported behavior space: direct field deepcopy, form instance field cloning, and
deep rather than shallow copying of `error_messages`.

Residual caveat: the K proof is constructed, not machine-checked, because this
task forbids running `kompile` or `kprove`. Tests should not be removed on the
basis of this audit alone.
