# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent mapping | Verdict | Notes |
| --- | --- | --- | --- |
| `ALLOW-DEFAULT-KWONLY` | Intent items 1 and 2 | Pass | Directly matches E1, E2, and E5. |
| `DUPLICATE-KWONLY` | Intent item 3 | Pass | Directly matches E3's expected error message. |
| `UNKNOWN-STILL-UNEXPECTED` | Intent item 5 | Pass | Preserves existing documented/public-test behavior for invalid names. |
| `MISSING-REQUIRED-KWONLY` | Intent item 6 | Pass | Preserves required keyword-only behavior already present in the helper. |
| Compatibility claim | Intent item 4 | Pass | Shared helper change covers both tag helpers without public API changes. |
| PO-6 adjacent positional-plus-keyword duplicate | Default-domain note | Ambiguous/unclaimed | Public issue does not require this broader compile-time diagnostic. It is not used to justify V1. |

None of the passing claims used to confirm V1 is supported only by
candidate-derived behavior. The only ambiguous point is explicitly excluded from
the success proof and recorded as F-5.
