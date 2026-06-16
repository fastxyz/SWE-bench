# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent item | Verdict | Notes |
| --- | --- | --- | --- |
| C1 `ESCAPESEQ-MAP` | Intent 2, 3; ledger E2, E3, E5 | Pass | Specifies same-order, same-length per-element escaping for arbitrary finite sequences. |
| C2 `CONDITIONAL-ESCAPE-RAW` | Intent 3; ledger E3, E4 | Pass | Models existing `escape` semantics for unsafe values through trusted `htmlEscape`. |
| C3 `CONDITIONAL-ESCAPE-SAFE` | Intent 4; ledger E4 | Pass | Prevents accidental `force_escape` behavior. |
| C4 `ESCAPESEQ-JOIN-OFF` | Intent 5; ledger E2, E6 | Pass | Models the exact pipeline named in the issue and keeps separator behavior unchanged. |
| S1 filter registration | Intent 1; ledger E1, E7 | Pass | The decorator registers the public filter name without changing other filters. |
| S2 docs coverage | Intent 7; ledger E8 | Pass after V2 docs edit | V1 lacked a docs entry; V2 adds it. |

## Adequacy conclusion

The formal English paraphrase is neither weaker nor stronger than the public
intent for the functional behavior. It intentionally treats the exact escaping
table as an existing Django dependency, which is adequate because this issue is
about adding a sequence filter that invokes that dependency per item.
