# FVK Notes

## Decision: keep V1 unchanged

V1 stands without additional source edits. `F-RESOLVED-OUTER-MI` identifies the
original defect as the outer presentation `mi` around an `msub`, and
`PO-SUB-NO-OUTER-MI` plus `PO-SPLIT-X2` show that V1 returns
`msub(mi("x"), mi("2"))` directly for the issue's `x2` case.

`F-SCRIPTED-FAMILY` broadened the audit from trailing-digit subscripts to the
whole scripted-symbol branch family. V1 already satisfies the corresponding
obligations: `PO-SUB-NO-OUTER-MI`, `PO-SUP-NO-OUTER-MI`, and
`PO-SUBSUP-NO-OUTER-MI`. Therefore no extra branch-specific code change is
needed.

## Decision: do not change `split_super_sub`

The public issue expects `x2` to render as a subscripted symbol, not literal
text. `PO-SPLIT-X2` and intent ledger entry `I4` preserve the existing
trailing-digits convention. Changing `split_super_sub` would contradict that
obligation, so V1's decision to leave it untouched is confirmed.

## Decision: do not change content MathML

`F-CONTENT-FRAME` and `PO-CONTENT-FRAME` classify the content printer as outside
the reported path. The issue uses `printer='presentation'` and its corrected
markup is presentation MathML. No content-printer edit is justified.

## Decision: keep the bold-style adjustment from V1

`F-BOLD-FRAME`, `PO-PLAIN-FRAME`, and `PO-BOLD-FRAME` require preserving plain
matrix-symbol output while avoiding the invalid outer wrapper for scripted
symbols. V1 applies `mathvariant="bold"` to the base `mi`; this keeps the exact
plain-symbol output and gives scripted matrix symbols a valid presentation
shape.

## Decision: do not edit tests

`F-SUSPECT-LEGACY-SHAPE-TESTS` explains that public tests expecting top-level
`mi` for scripted symbols encode the reported bug and are therefore SUSPECT
under the FVK intent-evidence rule. The benchmark forbids test edits, so no test
files were modified. `PO-ADEQUACY-LEGACY-TEST-CONFLICT` justifies not preserving
the old shape in production code.

## Verification status

The FVK proof is constructed, not machine-checked. I did not run tests, Python,
`kompile`, `kast`, or `kprove`. The exact future machine-check commands are
listed in `fvk/PROOF.md` and `fvk/ITERATION_GUIDANCE.md`.
