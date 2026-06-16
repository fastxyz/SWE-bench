# Spec Audit

Status: constructed, not machine-checked.

| Claim | Audit result | Rationale |
| --- | --- | --- |
| C1 marked skip with runxfail | Pass | Directly matches E1, E2, and E4: marker skip location must be item location and runxfail must not affect it. |
| C2 unmarked skip with runxfail | Pass | Matches E5 and avoids over-broadening the fix beyond marker skips. |
| C3 xfail exception with runxfail | Pass | Matches the option semantics in E4: runxfail suppresses xfail-specific handling. |
| C4 xfail exception without runxfail | Pass | Frame condition from E7: V1 must preserve non-runxfail xfail behavior. |

No claim depends on the pre-fix output `src/_pytest/skipping.py:238` as intended
behavior. That output is treated as SUSPECT legacy behavior and as the symptom
to remove.
