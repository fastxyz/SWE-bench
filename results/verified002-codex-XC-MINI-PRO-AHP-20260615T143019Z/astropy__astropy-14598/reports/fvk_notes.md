# FVK Notes

Status: constructed, not machine-checked. No tests, Python, or K tooling were
run.

## Decision

V1 stands unchanged.

The FVK audit found that the V1 source patch addresses both public failure
mechanisms and did not surface a justified additional production-code change.

## Trace To Findings And Proof Obligations

### Keep `fullmatch()` in `Card._split()`

Finding F2 identifies the pre-fix prefix-match bug: `_strg_comment_RE.match(vc)`
could accept a partial string field and leave continuation text unconsumed. PO2
requires full value/comment field consumption. The current V1 code uses
`_strg_comment_RE.fullmatch(vc)`, so it directly discharges PO2.

No further edit is needed for this finding.

### Keep Raw Escaped Payload Until `_parse_value()`

Finding F1 identifies the pre-fix double-unescape bug: `_split()` unescaped
`''` inside each physical chunk, and `_parse_value()` unescaped again. PO3
requires `_split()` to remove only the `CONTINUE` marker and not unescape
quotes. PO5 requires the final parser to unescape exactly once. The current V1
code removes the per-chunk `replace("''", "'")`, so it discharges PO3 and
lets the existing `_parse_value()` behavior discharge PO5.

No further edit is needed for this finding.

### Preserve Comments And Public Compatibility

Finding F3 confirms the compatibility frame: `_strg_comment_RE` has no other
callers, public method signatures are unchanged, header grouping is unchanged,
and comment collection remains on the existing path. PO7 captures those frame
conditions. Since V1 only changes how the long-card value payload is accepted
and accumulated, no compatibility repair is required.

### Do Not Broaden The Parser Rewrite

Finding F4 records a residual risk in the broader FITS string regex: existing
comments acknowledge leniency around malformed quote counts. That risk is
outside PO1-PO7, which are derived from the public issue and docs around valid
`CONTINUE` string values and the specific doubled-quote failure. A broader
strict-parser change would need a separate intent ledger because it could break
backward-compatible parsing of non-standard headers.

Therefore no additional source change is justified by F4.

## Artifacts Produced

- `fvk/SPEC.md`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`
- `fvk/mini-fits-card.k`
- `fvk/fits-card-spec.k`

The constructed proof commands are recorded in PO8 and `fvk/PROOF.md`, but they
were not executed due to the task constraints.
