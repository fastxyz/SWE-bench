# Spec Audit

Status: constructed, not machine-checked.

| Formal English Claim | Intent Entries | Result | Notes |
| --- | --- | --- | --- |
| `NONINTEGER-UNCHANGED` | Intent 1, 2; E1, E2 | Pass | Captures the reported `I` crash path. |
| `SYMBOLIC-POW-UNCHANGED` | Intent 2, 6; E2, E8 | Pass | Prevents a proof-required call to `perfect_power` outside its concrete domain. |
| `NEGATIVE-UNCHANGED` | Intent 3; E2 | Pass | Matches documented unchanged negative powers. |
| `MAX-UNCHANGED` | Intent 3; E3, E7 | Pass | Matches `sin(x)**10` with `max=4`. |
| `EXP2-REWRITE` | Intent 4; E2, E7 | Pass | Matches `TR5` and `TR6` examples. |
| `EXP4-REWRITE` | Intent 4; E2, E7 | Pass | Matches fourth-power examples. |
| `POW-FALSE-EVEN` | Intent 5; E2, E7 | Pass | Matches `sin(x)**6` with `pow=False`. |
| `POW-FALSE-ODD` | Intent 5; E2, E7 | Pass | Matches `sin(x)**3` unchanged. |
| `POW-TRUE-SIX` | Intent 6; E4, E5, E7 | Pass | Matches public example. |
| `POW-TRUE-EIGHT` | Intent 6; E4, E5, E7 | Pass | Matches public example. |
| `POW-TRUE-NINE` | Intent 6; E4, E6 | Pass | Closes V1's odd perfect-power gap. |

No claim rests solely on candidate behavior. No ordering, precedence, or public
API compatibility claim is ambiguous.
