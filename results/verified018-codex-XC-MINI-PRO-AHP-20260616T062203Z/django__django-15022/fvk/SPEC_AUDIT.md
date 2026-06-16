# Spec Audit

Status: adequacy review, constructed but not machine-checked.

| Formal item | Intent entries | Verdict | Notes |
| --- | --- | --- | --- |
| F1 | I1, I3 | Pass | The model preserves `smart_split()` token iteration and quote unescaping as token preparation. |
| F2 | I1, I2 | Pass | AND-of-ORs is exactly the documented SQL shape. |
| F3 | I1 | Pass | Whitespace-only or otherwise empty token streams previously applied no per-token filters; V2 preserves that behavior. |
| F4 | I5 | Pass | The issue specifically rejects the per-word `qs.filter(...)` loop. |
| F5 | I4, I5, D2 | Pass | Alias reuse reasoning is tied to current ORM source; not a backend planner proof. |
| F6 | I1, I3, I6 | Pass | Lookup construction code is unchanged by V2. |
| F7 | I6 | Pass | Duplicate detection code is unchanged. |
| F8 | I6 | Pass | Signature and return type are unchanged. |

## Ambiguity considered

Combining term clauses in one ORM filter can be stricter than chained filters
for multi-valued relations because it may require multiple predicates to be
satisfied through the same join alias rather than different related rows. The
public docs describe a single SQL `WHERE` clause and the issue demands avoiding
the repeated chained-filter join pattern. No public evidence requires the legacy
"different related rows may satisfy different words" behavior. This ambiguity is
recorded as finding F-003 and does not block V2.
