# FVK Notes

The FVK audit confirms V1 and makes no V2 source edits.

## Decisions

Decision 1: Keep `repo/django/contrib/admin/views/autocomplete.py` unchanged.

- Trace: F-001 confirms the inline-serialization defect is resolved.
- Trace: F-002 confirms the default result dictionary is preserved.
- Trace: F-003 confirms pagination and the response envelope are preserved.
- Trace: F-004 confirms public override compatibility.
- Trace: PO-1 through PO-5 collectively discharge the issue's extension point, default behavior, framing, and compatibility obligations.

Decision 2: Do not add a broader hook that receives `request`, `context`, or the complete result list.

- Trace: `fvk/SPEC.md` INT-1 and INT-4 require per-object result customization.
- Trace: PO-1 and PO-3 are satisfied by per-object dynamic dispatch.
- Trace: F-005 records that no proof obligation requires broader API surface.

Decision 3: Do not alter admin URL routing, widget code, queryset behavior, permission handling, or pagination.

- Trace: INT-3 and INT-5 in `fvk/SPEC.md` require preserving the surrounding response behavior.
- Trace: PO-4 frames pagination and the response envelope.
- Trace: F-003 confirms the V1 source changed only per-result serialization.

Decision 4: Do not run tests, Python, `kompile`, or `kprove`.

- Trace: F-006 records the environment limitation from the task instructions.
- Trace: PO-6 records the commands that would be run in a full environment.

## Outcome

V1 stands because the FVK findings are all resolved or non-blocking. The only residual limitation is that the proof is constructed, not machine-checked, so no test deletion is recommended.
