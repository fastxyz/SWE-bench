# FVK Notes

## Decision Summary

The FVK audit confirms the V1 source fix. No V2 source edits were made.

The core reason is Finding F1: V1 normalizes source paths in
`Catalog.__iter__()` before constructing `Message`, and `Message.__init__()`
then de-duplicates the normalized `(source, line)` pairs. This discharges PO1,
PO3, PO4, PO5, and PO6 for the reported duplicate location output.

## Decisions Traced To Findings And Obligations

1. Kept `_unique_locations()` unchanged.
   - Trace: F1, PO4, PO6.
   - Reason: the helper implements preserve-order uniqueness, which satisfies
     the no-duplicate location obligation without introducing unordered
     `set()` output.

2. Kept normalization in `Catalog.__iter__()` unchanged.
   - Trace: F1, PO3, PO5.
   - Reason: the public hint says exact tuple de-duplication is insufficient and
     that source paths must be normalized before `Message` sees them. The proof
     obligation models this as `N(source) = canon_path(relpath(source))`.

3. Kept renderer/template behavior unchanged.
   - Trace: PO3, PO7.
   - Reason: the path lemma in `fvk/SPEC.md` says rendering a normalized source
     preserves the retained output spelling. Changing the template was not
     needed to remove duplicates.

4. Did not change Babel PO wrapping or sorting behavior.
   - Trace: F2, PO1, PO7.
   - Reason: those suggestions are adjacent observations in the issue text, but
     the proven contract is duplicate removal in Sphinx's gettext location path.

5. Did not de-duplicate UUID comments.
   - Trace: F3, PO7.
   - Reason: the public issue examples and expected behavior describe duplicate
     file/line location comments, not `gettext_uuid` output.

6. Did not modify tests or run tests/K tooling.
   - Trace: F4, PO8.
   - Reason: the benchmark forbids execution. The FVK artifacts include the
     commands to run later and label the proof as constructed, not
     machine-checked.

7. Confirmed public compatibility.
   - Trace: F5, PO7, `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`.
   - Reason: V1 changes no public signature or virtual dispatch shape and keeps
     message iteration order intact.

## Artifacts Produced

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

Additional FVK adequacy and formal-core artifacts were also produced:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python-location-catalog.k`
- `fvk/gettext-location-spec.k`
