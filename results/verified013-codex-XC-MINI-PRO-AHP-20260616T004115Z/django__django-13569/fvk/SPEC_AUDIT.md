# Spec Audit

Status: constructed, not machine-checked.

| Formal item | Intent entry | Adequacy result | Notes |
| --- | --- | --- | --- |
| `DROP-RANDOM` | I1, I4 | Pass | Matches the issue's random-ordering complaint and the no-column hint. |
| `KEEP-COLUMN` | I2 | Pass | Preserves the public `order_by('related')` behavior described as expected. |
| `KEEP-RAWSQL` | I4 | Pass | Directly follows the public hint that raw SQL must still be included. |
| `KEEP-EXTERNAL-COLS` | I2, I5 | Pass | Required because subqueries can carry outer-column dependencies without direct `contains_column_references` metadata. |
| `DROP-REF` | I3 | Pass | Existing compiler comment provides direct public source-code intent. |
| `FILTER-STEP` | Domain | Pass | Models the finite list iteration in `get_group_by()` without changing ordering of retained expressions. |

V1 audit result: Fail on `KEEP-EXTERNAL-COLS`. V1 retained direct column
references and raw SQL, but a `Subquery` returned as its own group-by expression
because of `Query.get_external_cols()` could be dropped. This is recorded as
F1 in `FINDINGS.md` and fixed in V2.
