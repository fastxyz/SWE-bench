# Baseline Notes

## Root cause

`django.contrib.messages.storage.base.LEVEL_TAGS` was computed once at module
import time from `utils.get_level_tags()`. That helper merges
`constants.DEFAULT_TAGS` with the current `settings.MESSAGE_TAGS`, but the
module-level `LEVEL_TAGS` dictionary was never recomputed after
`override_settings(MESSAGE_TAGS=...)` sent Django's `setting_changed` signal.
As a result, `Message.level_tag` continued reading stale tag data and returned
an empty string for newly overridden message levels.

## Files changed

`repo/django/contrib/messages/storage/base.py`

Added a `setting_changed` receiver that listens for `MESSAGE_TAGS` updates and
rebuilds the module-level `LEVEL_TAGS` mapping with `utils.get_level_tags()`.
This keeps `Message.level_tag` backed by the active settings while preserving
the existing lookup behavior.

## Assumptions and alternatives considered

I assumed the correct behavior is for `LEVEL_TAGS` to reflect both entry into
and exit from `override_settings()`, since the signal is sent in both cases and
`utils.get_level_tags()` reads the currently active settings object.

I considered moving this into `django/test/signals.py`, but rejected that
because the existing comment there says contrib-app-related receivers belong
with the contrib app. The stale state also lives in the messages storage module,
so keeping the receiver beside `LEVEL_TAGS` is the most targeted change.

I considered replacing `LEVEL_TAGS` with a fresh `utils.get_level_tags()` call
inside `Message.level_tag`, but rejected that because it would change the
existing constant-based behavior for every lookup rather than only invalidating
the cache when the relevant setting changes.

Tests were not run, per the benchmark instruction not to execute code or tests
in this workspace.
