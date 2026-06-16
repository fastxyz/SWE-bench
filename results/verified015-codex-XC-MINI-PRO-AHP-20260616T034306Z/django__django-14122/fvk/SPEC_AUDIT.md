# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent entry | Result | Notes |
| --- | --- | --- | --- |
| `GROUPED-META-SUPPRESSED` | E1, E2, E3, E4 | Pass | It states the exact issue property and uses `grouped` as the non-`None` group state. |
| `UNGROUPED-META-PRESERVED` | E5 frame condition and Django default behavior | Pass | It prevents an overbroad fix that would remove metadata ordering from ordinary queries. |
| `GROUPED-EXPLICIT-PRESERVED` | E5 frame condition | Pass | It preserves explicit API ordering and does not treat it as metadata ordering. |
| `GROUPED-EXTRA-PRESERVED` | E5 frame condition | Pass | It preserves `extra_order_by`, the highest-precedence explicit ordering source. |

No claim is supported only by current candidate behavior. The only source-level
implementation facts used are the compiler precedence structure and the
documented `group_by` state shape; both are used to model how the code should be
checked, not to redefine the public issue intent.
