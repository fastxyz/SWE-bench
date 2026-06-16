# Spec Audit

Status: constructed, not machine-checked.

| Formal claim | Intent item | Result | Notes |
|---|---|---|---|
| PSD-SPECTRUM-SIGNED-SUM | Intent 1-3 | Pass | Encodes coherent-gain denominator for the affected branch. |
| PSD-SPECTRUM-NEGATIVE-DISCRIMINATOR | Intent 1-3 | Pass | Shows the negative-coefficient case is distinguishable. |
| LEGACY-NEGATIVE-DISCRIMINATOR | Intent 1-3 | Pass | Demonstrates why the pre-fix expression is wrong. |
| PSD-DENSITY-FRAME | Intent 4 | Pass | Keeps the density branch unchanged. |
| POSITIVE-WINDOW-FRAME | Intent 5 | Pass | Shows positive-window compatibility. |
| Complex windows excluded | Intent 7 | Ambiguous | Public evidence does not define desired complex-window behavior. This does not block V1 for the reported real-window bug. |

Adequacy conclusion: the formal claims match the public intent for real-valued
PSD spectrum scaling. They do not prove behavior for complex-valued windows,
and the artifacts do not use complex windows to justify `V2 == V1`.

