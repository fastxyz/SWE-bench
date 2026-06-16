# Spec Audit

Status: adequacy gate for the constructed claims; no execution performed.

| Formal obligation | Intent entry | Audit result | Notes |
|---|---|---|---|
| Compound `Pow` denominator bases are parenthesized. | Intent 1, 2; ledger E1-E5. | Pass | This is the missing case from the issue and the V1 fix. |
| Compound `Mul` denominator bases remain parenthesized. | Intent 3; ledger E7. | Pass | The V1 guard still includes `Mul`. |
| Atomic denominator bases are not newly parenthesized. | Intent 4; ledger E8. | Pass | V1 does not alter non-`Mul`/`Pow` atom cases. |
| Parser construction is unchanged. | Intent 5; ledger E4, E6. | Pass | Source evidence localizes the issue to printing. |
| Full SymPy printing semantics are not modeled. | Domain and frame conditions. | Ambiguous but bounded | The K model is intentionally minimal. The unmodeled scope is tracked as an escalation boundary in `FINDINGS.md`; source inspection covers the immediate branch and frame obligations. |

Conclusion: the formal claims match the public intent for the changed behavior. The only ambiguity is the expected FVK MVP limitation: the mini semantics is not a full Python/SymPy semantics.
