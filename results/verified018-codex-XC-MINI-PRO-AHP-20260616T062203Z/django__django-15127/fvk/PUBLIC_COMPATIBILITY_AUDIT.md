# Public Compatibility Audit

Status: constructed, not machine-checked.

## Changed Symbols

`django.contrib.messages.storage.base.update_level_tags(setting, **kwargs)`

- Status: new internal receiver function.
- Public compatibility: no public caller is expected; it is connected through
  Django's `setting_changed` signal.
- Signature compatibility: accepts the named `setting` argument and arbitrary
  signal kwargs (`sender`, `signal`, `value`, `enter`), matching Django signal
  receiver requirements.

`django.contrib.messages.storage.base.LEVEL_TAGS`

- Status: existing internal module mapping.
- V1 behavior: rebinding replaced the module global with a new mapping.
- V2 behavior: recomputes the new mapping first, then clears and updates the
  existing mapping object.
- Compatibility result: V2 preserves the public `Message.level_tag` behavior
  and also preserves existing direct references to the mapping object. The
  direct-reference case is not documented as public API, but preserving it is a
  low-risk strengthening.

`django.contrib.messages.storage.base.Message.level_tag`

- Status: public documented property.
- Compatibility result: no signature or return-type change. It still returns a
  string, using `''` when the level has no tag.

## Callsite and Override Audit

- `Message.level_tag` is a property, not a virtual method call with a changed
  signature.
- Storage backend subclass contracts (`_get`, `_store`) are untouched.
- No public producer/consumer storage format changes.
- No test files were modified.

Compatibility audit result: pass.
