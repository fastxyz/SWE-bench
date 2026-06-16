# Public Evidence Ledger

Status: constructed for FVK, not machine-checked.

| ID | Source | Evidence | Semantic obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | `benchmark/PROBLEM.md` | "LEVEL_TAGS not updated when using @override_settings" | `LEVEL_TAGS` must change when `MESSAGE_TAGS` is overridden in tests. | Encoded by PO-2 and claims `update-message-tags`, `message-level-tag-after-update`. |
| E2 | `benchmark/PROBLEM.md` | "Message.level_tag property results to be an empty string and not know the new tags." | `Message.level_tag` must return the configured custom tag for a configured custom level. | Encoded by PO-3 and claim `message-level-tag-after-update`. |
| E3 | `benchmark/PROBLEM.md` | "It should be possible to add a setting_changed receiver and update LEVEL_TAGS when needed." | A `setting_changed` receiver is an intended repair mechanism. | Encoded by PO-2. |
| E4 | `repo/docs/ref/contrib/messages.txt` | "To change the default tags for a message level (either built-in or custom), set the MESSAGE_TAGS setting..." | `MESSAGE_TAGS` applies to built-in and custom message levels. | Encoded by PO-1 and PO-3. |
| E5 | `repo/docs/ref/settings.txt` | "If you specify a value, it will extend the default." | Effective tags are default tags overridden/extended by `MESSAGE_TAGS`. | Encoded by PO-1. |
| E6 | `repo/docs/ref/contrib/messages.txt` | "`level_tag`: The string representation of the level... can be changed... by using the MESSAGE_TAGS setting." | `Message.level_tag` is the public observable. | Encoded by PO-3. |
| E7 | `repo/django/test/utils.py` | `override_settings.enable()` and `.disable()` send `setting_changed` with the setting name and active value. | The receiver must recompute on entry and exit from active settings. | Encoded by PO-4. |
| E8 | `repo/django/test/signals.py` | "Most setting_changed receivers are supposed to be added below, except for cases where the receiver is related to a contrib app." | A contrib messages receiver belongs with the messages code, not in the generic test signal file. | Encoded by file placement decision. |
| E9 | `repo/django/contrib/messages/storage/base.py` | V1 rebounded `LEVEL_TAGS = utils.get_level_tags()` inside the receiver. | Rebinding fixes module-global lookup but does not refresh an existing mapping reference. | Finding F-1, resolved in V2 by in-place refresh. |
