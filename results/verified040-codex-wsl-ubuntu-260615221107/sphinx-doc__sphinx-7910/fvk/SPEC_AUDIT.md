# Spec Audit

Status: pass for the audited unit, constructed and not machine-checked.

| Claim | Intent match | Notes |
| --- | --- | --- |
| C1 decorated method init | Pass | Directly matches I1-I3: the reported bug is wrapper globals not containing the class. |
| C2 decorated class init | Pass | Matches I7 under the default Python convention that `functools.update_wrapper`/`wraps` exposes `__wrapped__`. |
| C3 nested/private owner | Pass | Preserves existing nested-class module+qualname behavior from I4. |
| C4 top-level fallback | Pass | Preserves old direct globals behavior only when module lookup cannot resolve a top-level class. This is compatibility-preserving and does not weaken C1. |
| C5 no owner | Pass | Matches I5 and prevents broad force-inclusion of inherited or unrelated members. |
| C6 config gate | Pass | Matches I5-I6; the settings remain authoritative. |
| C7 module private | Pass | Matches existing module behavior in I6. |
| C8 weakref | Pass | Matches I6 and existing skip-member tests. |

No claim depends only on current V1 behavior. The two V2 changes are both tied
to public intent or compatibility evidence: F2 to I7 and F3 to I4/I8.
