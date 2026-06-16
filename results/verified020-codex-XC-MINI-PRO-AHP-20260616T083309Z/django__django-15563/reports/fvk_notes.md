# FVK Notes

Status: constructed, not machine-checked.

## Decision

V1 stands unchanged. The FVK audit did not surface a source-level problem against
the intent specification in `fvk/SPEC.md`.

## Trace from findings and proof obligations

`fvk/FINDINGS.md` F1 identifies the original defect: a related update for a
second concrete parent used the child/base primary key list instead of the
second parent-link ID list. `fvk/PROOF_OBLIGATIONS.md` PO1 and PO2 are the
corresponding required fix. V1 discharges them by selecting one related ID
column per related update model in `SQLUpdateCompiler.pre_sql_setup()` and by
using `self.related_ids[model]` in `UpdateQuery.get_related_updates()`.

F2 records the main audit risk: direct-only parent-link logic would be
insufficient for an indirect ancestor reached through a deeper MTI path. PO1
requires target-model-specific parent-link selection. V1 keeps the
`_get_update_related_id_lookup()` helper because it uses
`Options.get_path_to_parent()` and the final parent link's `attname`, which is
the metadata path needed for direct and indirect ancestors.

F3 and PO6 cover compatibility. No public API or return shape changed; the only
protocol change is private state shared by `SQLUpdateCompiler` and `UpdateQuery`.
That supports keeping the source change limited to the V1 files.

F4 is the remaining caveat: the proof artifacts are constructed but not
machine-checked because this task forbids running K tooling. It does not justify
a code edit; it only means tests should not be removed and the K commands in
`fvk/PROOF.md` would need to be run in a real verification environment.

## Source changes after FVK

No source files were edited during the FVK phase. The V1 source patch remains the
final code change.
