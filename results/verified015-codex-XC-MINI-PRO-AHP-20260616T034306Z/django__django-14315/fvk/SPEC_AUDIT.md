# Spec Audit

| Formal claim | Intent coverage | Verdict | Notes |
| --- | --- | --- | --- |
| PG-NO-OVERRIDES | Matches E2 and E4. | PASS | This is the direct issue requirement that PostgreSQL returns `None` instead of `{}` when no env vars are needed. |
| PG-WITH-OVERRIDES | Matches E3, E4, E8, and preserves current intended PostgreSQL env-variable behavior. | PASS | The issue only rejects the empty mapping; populated mappings remain required to avoid leaking passwords and to pass PostgreSQL client options. |
| RUNSHELL-NONE | Matches E1, E3, and default subprocess semantics. | PASS | `env=None` is the intended inherit-current-environment path. |
| RUNSHELL-EMPTY | Matches E1, E3, and E7. | PASS | This is the V1 audit gap: V1 fixed the PostgreSQL producer but not the shared consumer if an empty mapping arrived from another backend. |
| RUNSHELL-NONEMPTY | Matches E4 and existing base runner semantics. | PASS | Non-empty backend mappings are still overlaid onto `os.environ`. |
| PostgreSQL argument frame | Matches E4 and absence of any issue evidence about args. | PASS | The proof does not claim new argument behavior; the source edit does not touch argument construction. |
| Visible PostgreSQL tests expecting `{}` | Conflicts with E2 and E3. | SUSPECT | These tests encode the reported bug and cannot serve as the formal expected value. |

Adequacy result: the formal English matches the intent spec. No claim relies solely on V1 behavior.
