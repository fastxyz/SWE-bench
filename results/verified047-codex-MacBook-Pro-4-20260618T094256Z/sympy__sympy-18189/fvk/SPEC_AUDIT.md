# Spec Audit

Status: pass for the audited V1 branch; constructed, not machine-checked;
escalation-bounded for full solver internals.

| Intent obligation | Formal coverage | Audit result |
|---|---|---|
| `permute=True` completeness must not depend on `syms` ordering. | Claim C2 preserves symbolic `PERM`; Claim C4 instantiates the public issue with `PERM=true`. | Pass. |
| `syms` determines tuple position order. | Claim C2 returns `reorder(vars(EQ), SYMS, canonical(...))`. | Pass. |
| The pre-fix `{(3, 2)}` output is the bug, not the spec. | Ledger E3 marks it SUSPECT; Claim C4 requires `pow4_signed_nm`, not `pow4_base_nm`. | Pass. |
| Calls with omitted `syms` keep canonical behavior. | Claim C1. | Pass. |
| Calls with same-order `syms` keep canonical behavior. | Claim C3. | Pass. |
| Calls with `permute=False` in the reordered branch are not accidentally widened. | Claim C5. | Pass. |
| Public API and return shape remain unchanged. | `PUBLIC_COMPATIBILITY_AUDIT.md` records no signature, dispatch, or return-shape change. | Pass. |
| Full Diophantine solver correctness. | Abstracted as `canonical(EQ, P, PERM)`. | Escalation boundary, not used to justify a broader solver claim. |
| Total correctness and termination. | Not modeled. | Escalation boundary. |

## Adequacy Decision

The formal English matches the public issue intent for the changed branch: V1
forwards the caller's `permute` flag through the recursive solve, then performs
the existing tuple remap. No formal claim depends on the SUSPECT pre-fix output.

The audit does not claim machine-checked status and does not claim full SymPy
solver verification.
