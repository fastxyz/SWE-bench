# FVK Notes

## Decision

V1 stands unchanged. The FVK audit found no source change required for
django__django-12262.

## Trace to Findings and Proof Obligations

`repo/django/template/library.py` was kept as V1 because:

- F-1 maps to PO-1: the current code accepts declared keyword-only parameters
  with defaults because legality checks the complete `kwonly` list.
- F-2 maps to PO-2: the current code reports duplicate keyword names before
  unexpected-keyword validation.
- F-3 maps to PO-3 and PO-4: unknown keywords and missing required keyword-only
  parameters retain their existing diagnostics.
- F-4 maps to PO-5: the shared helper covers both `simple_tag()` and
  `inclusion_tag()` without signature changes.

No code was changed during the FVK pass because the only non-passing item, F-5 /
PO-6, is an adjacent positional-plus-keyword duplicate diagnostic that the issue
does not require and the proof does not use to justify V1.

## Artifacts

The primary requested artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

The FVK method also requires the formal and adequacy core, so I added:

- `fvk/mini-python.k`
- `fvk/template-tag-parse-bits-spec.k`
- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`

No tests, Python, or K tooling were run.
