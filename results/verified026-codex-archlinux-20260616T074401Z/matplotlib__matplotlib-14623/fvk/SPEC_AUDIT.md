# Spec Audit

Status: adequacy gate for the constructed FVK spec; not machine-checked.

| Claim | Intent Coverage | Verdict | Reason |
| --- | --- | --- | --- |
| C1 | Required by E1, E2, E3, E4, E7 | PASS | The claim directly states that reversed finite positive log limits remain reversed. |
| C2 | Required by E1, E2, E4, E6, E8 | PASS | The formal observable is the stored interval order, which is how Matplotlib reports inversion. |
| C3 | Required by E5 and default locator frame behavior | PASS | The fix must not turn ordinary increasing limits into inverted limits. |
| C4 | Required by E8 | PASS | The scale clamp is a frame condition for positive limits. |
| C5 | Required by E4 and existing log-domain policy | PASS | The issue does not require accepting nonpositive explicit limits or changing singular-limit expansion. |
| C6 | Required by E9 | PASS | Internal tick sorting is separate from stored view limit order. |

No claim depends only on V1's current output. The key order-preservation claim
is independently derived from the public issue and the `Axes.set_xlim` /
`Axes.set_ylim` docstrings.

