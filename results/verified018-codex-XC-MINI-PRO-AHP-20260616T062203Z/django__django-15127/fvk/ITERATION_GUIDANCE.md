# Iteration Guidance

Status: constructed, not machine-checked.

## Code Decision

Revise V1 minimally by changing the receiver from rebinding `LEVEL_TAGS` to
refreshing the existing mapping in place.

Trace:

- Finding F-1 identified the stale-direct-reference compatibility edge.
- PO-2 requires refresh on `MESSAGE_TAGS`.
- PO-6 justifies preserving the mapping object's identity.

No other source change is recommended. The receiver remains in
`django.contrib.messages.storage.base` because E8 supports contrib-app-local
signal receivers and the stale state is local to that module.

## Tests to Add or Keep

Do not modify test files in this benchmark. Recommended tests for a normal
Django patch:

- `override_settings(MESSAGE_TAGS={50: 'critical'})` makes
  `Message(50, 'x').level_tag == 'critical'`.
- After the override exits, `Message(50, 'x').level_tag == ''` unless the
  restored settings also define level `50`.
- An unrelated `setting_changed` event does not alter `LEVEL_TAGS`.
- Optional internal compatibility: an existing reference to `LEVEL_TAGS`
  observes the in-place refresh.

## Tests Not Safe to Remove Yet

No test should be removed based on this pass. Test-redundancy recommendations
are conditioned on running the K commands and receiving `#Top`.

## Open Questions

No user clarification is needed for the reported issue. Public intent is
sufficient for the receiver placement and behavior.
