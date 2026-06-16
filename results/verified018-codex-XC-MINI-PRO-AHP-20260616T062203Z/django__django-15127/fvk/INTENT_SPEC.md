# Intent Spec

Status: constructed for FVK, not machine-checked.

## Scope

This FVK pass audits the behavior changed by the V1 fix for
`django__django-15127`: the relationship between `MESSAGE_TAGS`,
`django.contrib.messages.storage.base.LEVEL_TAGS`, and
`Message.level_tag` when `override_settings()` sends `setting_changed`.

The audited code units are:

- `django.contrib.messages.utils.get_level_tags()`
- `django.contrib.messages.storage.base.update_level_tags()`
- `django.contrib.messages.storage.base.Message.level_tag`

`BaseStorage` loading/storing behavior is out of scope because the issue
concerns tag lookup after messages are read, not storage persistence.

## Required Behavior

I1. `MESSAGE_TAGS` extends the default message tags. A configured tag for a
level overrides the default tag for that level; levels absent from both maps
produce no level tag.

I2. `Message.level_tag` must read from the current effective tag map. For a
custom level supplied by `MESSAGE_TAGS`, the property returns that configured
tag instead of `''`.

I3. Entering `override_settings(MESSAGE_TAGS=...)` must make the overridden
tags visible to `Message.level_tag` for messages read inside the override.

I4. Exiting `override_settings(MESSAGE_TAGS=...)` must restore
`Message.level_tag` to the restored settings value, because Django sends
`setting_changed` on both entry and exit.

I5. A `setting_changed` event for any setting other than `MESSAGE_TAGS` must
not change `LEVEL_TAGS`.

I6. The fix must not change the public `Message` API or storage backend APIs.
The new receiver may be an internal helper.

I7. Because the issue and hint name `LEVEL_TAGS` as the stale module state,
refreshing the existing mapping object in place is preferred to rebinding it:
it makes both `base.LEVEL_TAGS` and existing direct references to that mapping
observe the refresh. The public documentation does not advertise direct
imports of `LEVEL_TAGS`, so this is a compatibility strengthening rather than
a required public API commitment.
