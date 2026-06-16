# Spec Audit

Status: constructed, not machine-checked.

| Formal-English claim | Intent source | Audit result |
|---|---|---|
| `dupClearDenoms(F)` returns the lcm denominator and `dupStrip(dupMulGround(F, C))`. | Intent items 1-4; ledger E1-E5 | Pass. It preserves denominator clearing and adds the canonicalization the issue requires. |
| A one-term zero after denominator multiplication becomes `.Poly`/`[]`. | Intent items 3-4; ledger E3 | Pass. This is exactly the reported `DMP([EX(0)])` -> `DMP([])` obligation. |
| `dmpClearDenoms(F)` uses recursive stripping after multiplication. | Intent item 5; ledger E6; full-intent generalization to recursive dense polys | Pass. A top-level-only strip would miss an inner `[0]`; recursive dense representation needs recursive canonicalization. |
| Return tuple/API shapes are unchanged. | Intent out-of-scope; compatibility audit | Pass. No signatures or return arity changed. |
| Expression simplification rules are unchanged. | Intent out-of-scope | Pass. The spec only acts after a coefficient is recognized as zero. |
| Termination is not proved. | FVK default partial correctness | Pass with caveat. No total-correctness claim is made. |

No claim is derived solely from V1 behavior. The V1 behavior that matches the
spec is accepted only because it is independently supported by the issue's
representation obligation and the dense canonicalization helpers already present
in SymPy.
