# FVK Notes

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged.

The FVK audit found that the V1 source change satisfies the core issue:

- `fvk/FINDINGS.md` F1 identifies the original bug as the no-op reverse for
  `RenameIndex(old_fields=...)`.
- `fvk/PROOF_OBLIGATIONS.md` PO1 requires backwards to restore the generated old
  name with `schema_editor._create_index_name(..., suffix="_idx")`.
- V1 does exactly that in `RenameIndex.database_backwards()` by resolving target
  model columns, constructing `old_index` as `new_name`, constructing
  `new_index` as the generated name, and delegating to
  `schema_editor.rename_index()`.

## Why no additional code edit was made

`fvk/FINDINGS.md` F1 and `fvk/PROOF_OBLIGATIONS.md` PO2 show that restoring the
generated name is enough to make the forwards/backwards/forwards sequence avoid
the reported rename-to-self crash. PO3 confirms the V1 guard preserves
`allow_migrate_model()` behavior. PO4 confirms the existing schema-editor
backend abstraction is preserved.

I considered whether to extend the fix to `unique_together` because the problem
prose uses that word. I rejected that change based on F3, PO5, and PO6:
`RenameIndex.old_fields` state handling removes `index_together`, not
`unique_together`, and the forward database lookup searches for `index=True`.
Adding `_uniq` handling here would be a broader operation-semantics change not
justified by this audit.

## Artifacts written

The required FVK artifacts are:

- `fvk/SPEC.md`
- `fvk/FINDINGS.md`
- `fvk/PROOF_OBLIGATIONS.md`
- `fvk/PROOF.md`
- `fvk/ITERATION_GUIDANCE.md`

To satisfy the FVK adequacy contract, I also wrote:

- `fvk/INTENT_SPEC.md`
- `fvk/PUBLIC_EVIDENCE_LEDGER.md`
- `fvk/FORMAL_SPEC_ENGLISH.md`
- `fvk/SPEC_AUDIT.md`
- `fvk/PUBLIC_COMPATIBILITY_AUDIT.md`
- `fvk/mini-python.k`
- `fvk/rename-index-spec.k`

## Verification constraints

Per task instructions, I did not run tests, Python, `kompile`, `kast`, or
`kprove`. F4 and PO7 record that the proof is constructed only and test removal
is not recommended without later machine-checking.
