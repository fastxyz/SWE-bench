# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent coverage | Verdict |
| --- | --- | --- |
| `DATE-SUB` | E1 and E6 require temporal subtraction to produce duration; date subtraction is part of the existing temporal family. | Pass |
| `DATETIME-SUB` | E1 and E2 directly require the reported datetime subtraction to produce duration. | Pass |
| `TIME-SUB` | E1 and E6 require the same rule for the existing temporal family used by SQL rendering. | Pass |
| `ISSUE-NESTED-DATETIME-DURATION` | E2/E3 require the reported nested expression to avoid `DateTimeField + DurationField` mixed inference. | Pass |
| `GENERIC-SAME-DURATION` | E2 requires the outer expression to resolve after the inner subtraction contributes `DurationField`; E7 supports using generic same-type inference. | Pass |
| `GENERIC-MIXED-DATETIME-DURATION` | E7 and the issue scope require unrelated direct mixed arithmetic to keep existing generic behavior. | Pass |
| `GENERIC-SAME-INTEGER` | E7 requires generic same-type behavior outside temporal subtraction to remain delegated. | Pass |
| `SQL-TEMPORAL-SUBTRACTION` | E4/E5 require existing SQL specialization to remain aligned and unchanged. | Pass |
| `SQL-TEMPORAL-SUBTRACTION-OUTPUT` | E4 states `TemporalSubtraction.output_field` is `DurationField`. | Pass |

No claim is candidate-derived without public/source evidence. No claim preserves
the reported legacy mixed-type failure.
