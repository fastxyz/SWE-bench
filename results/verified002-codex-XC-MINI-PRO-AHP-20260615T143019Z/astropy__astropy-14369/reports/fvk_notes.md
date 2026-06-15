# FVK Notes

## Decision Summary

V1 stands unchanged. No source files were edited during the FVK iteration.

## Traceability

The root bug remains the right-recursive division behavior described in
`fvk/FINDINGS.md` F-001. `fvk/PROOF_OBLIGATIONS.md` PO-1 and PO-2 show why the
V1 `_CDSUnit.division_tail` mechanism fixes the full chained-division family
required by the public issue, not just one printed example.

I considered whether V1 might over-flatten every slash after the first. That
would be wrong for explicit grouping such as `J/(m/s)`. `fvk/FINDINGS.md` F-002
and PO-3 show that V1 resets `division_tail` for parenthesized `combined_units`,
so explicit grouping remains atomic to the surrounding division. No code change
was needed.

I considered whether changing the grammar to left recursion or regenerating
`cds_parsetab.py` was necessary. `fvk/FINDINGS.md` F-003 and PO-6 show that V1
left the grammar productions, token list, production names, and arities
unchanged. The shipped parser table remains compatible with the semantic-action
change, so no generated file edit was justified.

I checked public compatibility. PO-7 records that V1 adds only private helper
state and leaves `CDS.parse` and the `ascii.cds` caller shape unchanged. That
supports the decision not to broaden the patch.

`fvk/FINDINGS.md` F-004 records that no unresolved source-code issue surfaced
after discharging PO-1 through PO-7. The residual caveat is proof status only:
the K artifacts and proof are constructed, not machine-checked, because this
task forbids running K tooling, tests, or Python.

## Artifacts Written

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-cds-units.k`
- `fvk/cds-parser-spec.k`

## Commands Not Run

The FVK artifacts include the exact `kompile`, `kast`, and `kprove` commands for
a later environment. They were not executed in this session. The suggested
Astropy pytest commands in `fvk/ITERATION_GUIDANCE.md` were also not run.
