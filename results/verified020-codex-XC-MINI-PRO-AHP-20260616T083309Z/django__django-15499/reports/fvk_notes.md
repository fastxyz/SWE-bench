# FVK Notes

## Decision

V1 stands unchanged.

The FVK audit found no open source-code finding. `fvk/FINDINGS.md` entries
FVK-F1 through FVK-F4 are closed by `fvk/PROOF_OBLIGATIONS.md` entries PO1
through PO7. FVK-F5 is the required honesty note that the proof is constructed,
not machine-checked, because the benchmark forbids running K tooling, Python, or
tests.

## Source decision trace

No additional source edit was made after V1.

- FVK-F1 identified the missing same-model manager reduction. PO1 and PO2 show
  V1 returns a one-element list containing `CreateModel` with the original name,
  fields, options, and bases.
- FVK-F2 identified the risk of merging managers instead of replacing them. PO3
  shows V1 uses `managers=operation.managers`, matching
  `ProjectState.alter_model_managers()`.
- FVK-F3 covered the empty-manager case. PO7 shows `managers=[]` remains the
  final state instead of preserving old managers.
- FVK-F4 covered the cross-model guard. PO4 shows V1 requires
  `self.name_lower == operation.name_lower`.
- PO5 proves the original two-operation state transition and the optimized
  one-operation state transition end with the same model-state tuple.
- PO6 confirms no database schema behavior is lost because
  `AlterModelManagers.database_forwards()` and `.database_backwards()` are no-op
  methods.

## Artifact decisions

I wrote the five requested FVK artifacts:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

I also wrote the supporting adequacy and K-core artifacts required by the FVK
method:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-migration-optimizer.k`
- `fvk/create-model-reduce-spec.k`

## Verification status

No tests, Python, or K tooling were run. The emitted K commands in `fvk/SPEC.md`
and `fvk/PROOF.md` are for later machine-checking only.
