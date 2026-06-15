# FVK Notes

The FVK audit confirms V1 as the correct source change for the targeted issue.
No additional edits under `repo/` were made during the FVK phase.

## Decisions

1. Kept `escape()` as `mark_safe(_html_escape(str(text)))`.
   - Traced to `fvk/FINDINGS.md` F1.
   - Discharges `fvk/PROOF_OBLIGATIONS.md` PO1, PO2, PO3, and PO5.
   - Rationale: public intent requires stdlib `html.escape()` while Django's
     wrapper still has to coerce with `str()` and return safe output.

2. Kept the apostrophe output change to `&#x27;`.
   - Traced to `fvk/FINDINGS.md` F2.
   - Discharges `fvk/PROOF_OBLIGATIONS.md` PO5 and PO9.
   - Rationale: visible legacy expectations for `&#39;` conflict with the issue's
     explicit note that stdlib uses `&#x27;`; those tests are SUSPECT evidence, not
     a reason to preserve the old literal.

3. Kept the `urlize()` helper support for `&#x27;`.
   - Traced to `fvk/FINDINGS.md` F3.
   - Discharges `fvk/PROOF_OBLIGATIONS.md` PO8.
   - Rationale: once `escape()` can produce `&#x27;`, the same module's escaped-URL
     helper should accept that spelling wherever it already accepted `&#39;`.

4. Did not broaden the fix to stdlib `html.unescape()` inside `urlize()`.
   - Traced to `fvk/ITERATION_GUIDANCE.md` "Rejected Changes".
   - Rationale: the proof obligation is narrow compatibility with entities this
     module produces. Broad entity unescaping could alter URL behavior without
     public issue evidence.

5. Did not modify tests or documentation.
   - Traced to `fvk/FINDINGS.md` F2 and F4.
   - Rationale: benchmark instructions forbid test edits, and the constructed
     proof is not machine-checked, so no test-removal recommendation is active.

## Verification Caveat

The proof artifacts are constructed and not machine-checked, per
`fvk/PROOF.md` and `fvk/FINDINGS.md` F4. The recorded K commands are intended
for a future environment with K installed; they were not executed here.
