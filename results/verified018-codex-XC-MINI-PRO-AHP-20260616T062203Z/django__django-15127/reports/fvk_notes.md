# FVK Notes

## Decision Summary

The FVK audit found that the V1 receiver was correctly placed and fixed the
reported `Message.level_tag` symptom, but it refreshed `LEVEL_TAGS` by rebinding
the module global. Finding F-1 and proof obligation PO-6 identified a small
compatibility edge: an existing direct reference to the mapping object would
remain stale. V2 changes the receiver to compute the new tags, then `clear()`
and `update()` the existing `LEVEL_TAGS` mapping.

## Source Changes

`repo/django/contrib/messages/storage/base.py`

- Kept the `setting_changed` receiver introduced in V1.
- Replaced `global LEVEL_TAGS; LEVEL_TAGS = utils.get_level_tags()` with an
  in-place refresh:
  `level_tags = utils.get_level_tags(); LEVEL_TAGS.clear();
  LEVEL_TAGS.update(level_tags)`.
- Trace: Finding F-1, PO-2, and PO-6.

## Decisions to Keep V1 Structure

The receiver remains in `storage.base` rather than `django.test.signals`.
Trace: evidence E8 in `PUBLIC_EVIDENCE_LEDGER.md` says contrib-app-related
receivers are exceptions to the generic test-signal location; PO-2 localizes the
state refresh to the module that owns `LEVEL_TAGS`.

`Message.level_tag` still performs `LEVEL_TAGS.get(self.level, '')`.
Trace: PO-3 and Finding F-2 show this lookup is the documented observable once
PO-2 keeps the map fresh. Replacing the property with a fresh
`utils.get_level_tags()` call on every access would be broader than required.

## Verification Status

The FVK artifacts are under `fvk/`. The proof is constructed, not
machine-checked. No K commands, tests, Python code, or Django code were executed
in this workspace.

The relevant commands are recorded in `fvk/SPEC.md` and `fvk/PROOF.md` for a
K-enabled environment.
