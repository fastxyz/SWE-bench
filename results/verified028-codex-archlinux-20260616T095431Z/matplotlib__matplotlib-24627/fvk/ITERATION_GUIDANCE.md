# FVK Iteration Guidance

Status: V1 stands unchanged.

## Decision

No V2 source edit is justified by this FVK pass. The audit surfaced the same
issue mechanisms captured by V1 and discharged the relevant proof obligations:

- F-001 and PO-2 justify keeping the axes-clear snapshots and detachment calls.
- F-002 and PO-3 justify keeping the figure-clear snapshots and detachment
  calls.
- F-003 and PO-4 justify not detaching retained axis and spine objects.
- PO-5 justifies that no public compatibility repair is needed.
- F-004 and PO-6 require the proof to remain labeled constructed, not
  machine-checked.

## Recommended Follow-Up Tests

If an execution environment becomes available, add or confirm tests for:

- `a.cla()` after `a.plot(...)`: the old line has `axes is None` and
  `figure is None`.
- `f.clf()` after plotting into an axes: the old line has `axes is None` and
  `figure is None`.
- `f.clf()` after `f.text(...)`: the old text has `figure is None`.
- `a.cla()` after `a.legend(...)`: the old legend has `axes is None` and
  `figure is None`.
- `a.cla()` leaves retained `a.xaxis` and `a.spines[...]` parented to `a`.

Do not delete existing tests based on this FVK run unless the K commands in
`PROOF.md` are later run successfully and the relevant tests are shown to be
strictly subsumed.

## Commands To Run Later

These are recorded for a future environment with K installed:

```sh
kompile fvk/mini-matplotlib-clear.k --backend haskell
kast --backend haskell fvk/matplotlib-clear-spec.k
kprove fvk/matplotlib-clear-spec.k
```

## Next Code-Generation Prompt If This Fails Later

If later machine checking or tests find a counterexample, localize it by asking:

1. Which parent-owned container dropped the artist without applying
   `_remove_artist_from_parent()`?
2. Was the object actually deparented, or merely reset in place?
3. Is the object a compound artist whose public parent reference differs from
   an internal auxiliary artist reference?
4. Does the failing path come from a subclass override of `clear()` / `cla()`
   that bypasses `_AxesBase.__clear()`?

Only apply a new source edit when the counterexample maps to a public-intent
obligation like F-001 or F-002.
