# Spec Audit

Status: constructed, not machine-checked.

| Claim | Public intent match | Notes |
|---|---|---|
| C1 MySQL literal adaptation | pass | Required by E1, E2, and E3; mirrors exact lookup pattern E5. |
| C2 SQLite literal adaptation | pass | Required by E1, E2, and E3; mirrors exact lookup pattern E5. |
| C3 Oracle scalar/string adaptation | pass | Required by E1, E2, and E4; quote-safe literal construction is required by I7. |
| C4 Oracle array/object adaptation | pass | Supported by E2's exact parity and existing exact lookup pattern E5. |
| C5 Native JSON/expression preservation | pass | Required by E6 frame conditions and the public note that PostgreSQL already works. |
| C6 Oracle large-list splitting | pass | Required by preserving generic `In` mechanics E6 over the full list-length family. |
| C7 Lookup dispatch | pass | Required for the specialized behavior to be reachable from public ORM syntax. |

No claim is based solely on V1 behavior. The two source changes beyond V1 are justified by audit failures:

- V1 did not satisfy C6 for Oracle large direct-literal lists.
- V1 did not satisfy C3 for Oracle strings containing SQL single quotes.
