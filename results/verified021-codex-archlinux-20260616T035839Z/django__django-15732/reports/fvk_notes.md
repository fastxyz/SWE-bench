# FVK Notes

## Decisions

1. V1 fixed the reported deletion failure, but FVK Finding F-001 identified an
   unnecessary compatibility risk: the helper signature had been widened to pass
   `_uniq`. Proof obligation O8 required preserving the original helper argument
   list where possible, so V2 restores
   `_delete_composed_index(self, model, fields, constraint_kwargs, sql)` and
   derives the `_uniq` preference internally.

2. V2 keeps the core V1 behavior because F-002 and proof obligations O1-O4 show
   it is required by the public issue: primary keys are excluded with
   `primary_key=False`, and multiple non-primary unique candidates are
   disambiguated by Django's generated `_uniq` name.

3. V2 does not change `alter_index_together()` because O7 limits the generated
   `_uniq` preference to unique deletion. Applying it to non-unique index
   deletion would be outside the issue evidence and was not needed to discharge
   F-002.

4. V2 does not attempt to fix the creation-path comment from the issue thread.
   F-003 and O9 record this as an underspecified follow-up: the public evidence
   names the scenario but later says it could not be reproduced, and a safe fix
   would require choosing a broader migration-state policy.

5. V2 accepts the manually-renamed-constraint residual risk. F-004 and O10 trace
   this to the public hint that generated Django names can be treated as the
   supported disambiguator for this issue.

## Artifacts

The required FVK artifacts are in `fvk/SPEC.md`, `fvk/FINDINGS.md`,
`fvk/PROOF_OBLIGATIONS.md`, `fvk/PROOF.md`, and
`fvk/ITERATION_GUIDANCE.md`.

Supporting FVK adequacy and formal-core artifacts are also present:
`fvk/INTENT_SPEC.md`, `fvk/PUBLIC_EVIDENCE_LEDGER.md`,
`fvk/FORMAL_SPEC_ENGLISH.md`, `fvk/SPEC_AUDIT.md`,
`fvk/PUBLIC_COMPATIBILITY_AUDIT.md`, `fvk/mini-schema-editor.k`, and
`fvk/schema-editor-spec.k`.

No tests, Python, or K tooling were run.
