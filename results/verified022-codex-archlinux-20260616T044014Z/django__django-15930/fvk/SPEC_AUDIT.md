# Spec Audit

| Formal-English item | Intent coverage | Verdict |
|---|---|---|
| Full-condition case renders `CASE WHEN 1=1 THEN True ELSE False END`. | Matches intent items 1 and 2: no empty `WHEN`, and all rows select `True`. Uses evidence E1-E5 and E8-E9. | Pass |
| Non-empty predicate rendering is unchanged and parameter order is preserved. | Matches intent item 4 and frame condition item 5. Uses evidence E8 and the narrow V1 diff. | Pass |
| Impossible predicate case falls through to default. | Matches intent item 3 and public test evidence E6-E7. | Pass |
| Scope excludes full ORM/database execution. | Acceptable FVK abstraction boundary: the modeled observable is the SQL fragment that caused the reported failure. Integration behavior still needs tests. | Pass with residual risk |

No formal claim relies solely on V1's current output as intent. The only
candidate-derived fact used is the implementation transition being checked
against public intent.
