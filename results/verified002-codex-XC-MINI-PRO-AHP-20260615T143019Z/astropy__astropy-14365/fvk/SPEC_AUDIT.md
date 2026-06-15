# Spec Audit

Status: adequacy audit for constructed FVK claims; not machine-checked.

| Formal obligation | Intent entry | Verdict | Notes |
|---|---|---|---|
| `LINE-TYPE-CASE-INSENSITIVE-READ-ERR` | E1, E3 | pass | Matches the issue requirement for case-insensitive supported QDP error commands. |
| `LINE-TYPE-LOWERCASE-SERR-WITNESS` | E2 | pass | Captures the exact failing example from the issue. |
| `LINE-TYPE-UPPERCASE-SERR-FRAME` | E3 | pass | Preserves documented uppercase behavior. |
| `LINE-TYPE-MIXEDCASE-TERR` | E1, E3 | pass | Generalizes the same case-insensitive command rule to the other supported error directive. |
| `ERR-SPEC-KEY-SERR-NORMALIZED` | E2, E4 | pass | Matches existing downstream `.lower()` behavior and the expected error-column interpretation. |
| `ERR-SPEC-KEY-TERR-NORMALIZED` | E1, E3, E4 | pass | Required for parity with `SERR` and supported by the same command grammar. |
| Broader QDP directives outside `READ SERR`/`READ TERR` | E6 | ambiguous | The prompt phrase "all commands" could be read broadly, but the concrete issue, local docs, and implementation support only error-column commands. This does not block V1 because the reported failure is in the supported grammar. |

No claim is derived solely from V1 behavior. The implementation contributes the
mechanism and propagation path, while the expected observable behavior comes
from the public issue and local QDP docs.
