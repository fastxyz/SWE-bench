# Spec Audit

| Formal claim | Intent coverage | Result |
|---|---|---|
| MC-MAX | Matches intent entries 1 and 5: `Max` must use Mathematica bracket-call syntax, and the defect is parenthesized fallback output. | PASS |
| MC-MIN | Matches intent entry 2 and evidence E3: `Min` is the named homogeneous sibling of `Max` in the public hint. | PASS |
| MC-FUNCTION-FRAME | Matches intent entry 3 and evidence E5: ordinary function bracket formatting must remain unchanged. | PASS |
| MC-EXPR-FALLBACK-FRAME | Matches the minimality/frame condition from the task and V1 notes: the fix should not broadly refactor unsupported expression fallback. | PASS |
| Argument order side condition | Matches intent entry 4 and evidence E8: claims are over `expr.args`, not the source order typed by the user. | PASS |
| Whitespace side condition | Matches intent entry 5 and public printer style evidence: the issue is bracket syntax, not comma spacing. | PASS |
| Lowercase `max` exclusion | Matches intent entry 6 and evidence E4. | PASS |

No claim is legacy-derived in a way that weakens the public issue intent. The
only legacy behavior retained is the explicit frame condition for unsupported
non-`Max`/`Min` expressions, which is justified by the task's minimal-change
requirement and by the absence of public intent to change generic fallback.
