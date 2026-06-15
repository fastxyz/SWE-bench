# FVK Notes

## Decision summary

V1 stands unchanged. The audit found that the V1 guard in `BaseModelAdmin.formfield_for_manytomany()` is exactly the required source change for the public issue.

## Decisions traced to findings and obligations

1. Kept the V1 source edit.
   - Finding trace: F-001 identifies the pre-fix overwrite as the issue.
   - Obligation trace: OBL-001 proves the explicit widget path now skips admin widget assignment and preserves the caller's widget.

2. Made no additional edit to admin default widget selection.
   - Finding trace: F-002 confirms V1 preserves behavior when `widget` is absent.
   - Obligation trace: OBL-002 covers autocomplete, raw-id, filtered select, and default-widget branches.

3. Made no edit to queryset handling, through-model handling, or `formfield_for_dbfield()`.
   - Finding trace: F-003 confirms those paths are frame conditions, not remaining defects.
   - Obligation trace: OBL-003 covers queryset precedence, OBL-004 covers the non-auto-created through early return, and OBL-005 covers `formfield_overrides` merge precedence.

4. Made no public API or compatibility changes.
   - Finding trace: F-004 confirms the method signature and override protocol remain compatible.
   - Obligation trace: OBL-006 covers public overrides and callsites.

5. Ran no tests and no formal tooling.
   - Finding trace: F-005 records the proof caveat.
   - Obligation trace: `PROOF_OBLIGATIONS.md` and `PROOF.md` record the commands to run later instead of executing them.

## Final state

Changed production source remains limited to `repo/django/contrib/admin/options.py` from V1. New FVK artifacts are under `fvk/`, and this report records why no V2 source change was necessary.
