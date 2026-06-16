# Proof Obligations

Status: constructed, not machine-checked.

## PO-1: Effective Tag Map

For default tags `D` and active setting tags `S`, `utils.get_level_tags()`
returns `mergeTags(D, S)`, where values in `S` override values in `D` and
levels in only one map are preserved.

Evidence: `utils.get_level_tags()` returns `{**constants.DEFAULT_TAGS,
**getattr(settings, 'MESSAGE_TAGS', {})}`; public docs say `MESSAGE_TAGS`
extends the default.

## PO-2: Receiver Refresh on MESSAGE_TAGS

When `setting_changed` invokes `update_level_tags()` with
`setting == 'MESSAGE_TAGS'`, the receiver must refresh `LEVEL_TAGS` to the
current effective tag map.

V2 discharges this by:

1. Computing `level_tags = utils.get_level_tags()`.
2. Clearing the existing `LEVEL_TAGS` mapping.
3. Updating it with `level_tags`.

## PO-3: Message.level_tag Lookup

For a `Message` with integer level `L`, `Message.level_tag` returns
`LEVEL_TAGS.get(L, '')`.

Therefore, after PO-2, it returns:

- the overridden configured tag for `L` when `L in S`;
- the default tag when `L in D` and `L not in S`;
- `''` when `L` is in neither map.

## PO-4: Override Entry and Exit

`override_settings()` sends `setting_changed` after installing the override and
again after restoring the previous settings. Since PO-2 recomputes from active
settings, entry and exit both produce the effective tag map for the currently
active settings.

## PO-5: Frame for Unrelated Settings

If `setting != 'MESSAGE_TAGS'`, the receiver must leave `LEVEL_TAGS` unchanged.
V2 discharges this because the function body has no side effect outside the
`if setting == 'MESSAGE_TAGS'` branch.

## PO-6: Mapping Identity Compatibility

The issue names stale `LEVEL_TAGS` state. Refreshing the existing mapping
object, rather than rebinding the global name, preserves any already-held
reference to that mapping while satisfying all public `Message.level_tag`
obligations.

## PO-7: API Frame

The fix must not change public method/property signatures or storage backend
interfaces. V2 adds only an internal receiver and changes only the contents of
the internal tag mapping.
