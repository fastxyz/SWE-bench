# Proof Obligations

Status: constructed, not machine-checked.

## Obligations

### PO-001: Rule-shape frame condition

SIM201 and SIM202 must still emit diagnostics only for their existing shapes:

- SIM201: `UnaryOp::Not` over a single `CmpOp::Eq` comparison.
- SIM202: `UnaryOp::Not` over a single `CmpOp::NotEq` comparison.

The existing exception-check and dunder-method suppression remain unchanged.

### PO-002: Applicability decision

For both SIM201 and SIM202:

```text
applicability(left, right) = Safe   iff known_bool_cmp(left) and known_bool_cmp(right)
applicability(left, right) = Unsafe otherwise
```

This is the central contract from E-001 through E-003.

### PO-003: Unknown calls are unsafe

An operand whose available evidence is an unknown call, including `np.array(...)`, must make the fix unsafe. A name bound to an unknown call inherits that unsafe classification.

### PO-004: Initializer evidence precedes annotation-only helpers

For a named operand with a binding value, V2 must classify the operand from `typing::find_binding_value` before consulting semantic helpers that may derive type knowledge from annotations.

This prevents `a: int = np.array([0])` from being treated as a known int for fix safety.

### PO-005: Replacement frame condition

The generated replacement expression must remain unchanged:

- SIM201 replaces `not left == right` with `left != right`.
- SIM202 replaces `not left != right` with `left == right`.

Only fix applicability changes.

### PO-006: Conservative incompleteness is allowed

If Ruff cannot prove an operand belongs to the known bool-comparison set, the fix must be unsafe even if the runtime type might actually be safe. This is an acceptable safe under-approximation.

### PO-007: Honesty gate

The proof is constructed, not machine-checked. No test deletion or confidence beyond the static proof sketch is justified until these commands are run successfully:

```sh
kompile fvk/mini-fix-applicability.k --backend haskell
kast --backend haskell fvk/sim20-fix-spec.k
kprove fvk/sim20-fix-spec.k
```
