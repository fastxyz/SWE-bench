# Proof

Status: constructed, not machine-checked.

## Claim Summary

The proof establishes partial correctness for the audited, terminating code
paths:

- `update_level_tags('MESSAGE_TAGS', ...)` refreshes the existing
  `LEVEL_TAGS` mapping to the active effective tag map.
- `update_level_tags(other_setting, ...)` leaves `LEVEL_TAGS` unchanged.
- `Message.level_tag` returns the tag found in the current effective map, or
  `''` when the level is absent.
- The composition of override entry/exit signals and the receiver gives the
  right tag map for both the overridden and restored settings.

There are no loops or recursive calls in the audited code, so no circularity is
needed.

## Symbolic Proof Sketch

### PO-1: Effective Tag Map

The source for `utils.get_level_tags()` constructs:

```python
{
    **constants.DEFAULT_TAGS,
    **getattr(settings, 'MESSAGE_TAGS', {}),
}
```

Python dictionary unpacking with later entries taking precedence gives
`mergeTags(D, S)`, where `S` overrides `D`. This discharges PO-1.

### PO-2: Receiver Refresh

For `setting == 'MESSAGE_TAGS'`, V2 executes:

```python
level_tags = utils.get_level_tags()
LEVEL_TAGS.clear()
LEVEL_TAGS.update(level_tags)
```

By PO-1, `level_tags == mergeTags(D, S)`. `clear()` removes all old entries
from the existing mapping object. `update(level_tags)` inserts exactly the
entries in `mergeTags(D, S)`. The object identity is unchanged because neither
operation rebinds `LEVEL_TAGS`. This discharges PO-2 and PO-6.

For `setting != 'MESSAGE_TAGS'`, the branch body does not execute. The mapping
is unchanged, discharging PO-5.

### PO-3: Lookup

`Message.level_tag` evaluates:

```python
LEVEL_TAGS.get(self.level, '')
```

After PO-2, `LEVEL_TAGS` contains `mergeTags(D, S)`, so the result is
`tagOf(mergeTags(D, S), L)`. This gives the configured tag, default tag, or
empty string exactly as specified.

### PO-4: Override Entry and Exit

`override_settings.enable()` installs the override and then sends
`setting_changed(setting='MESSAGE_TAGS', enter=True)`. `disable()` restores the
previous settings and sends `setting_changed(setting='MESSAGE_TAGS',
enter=False)`. Applying PO-2 to both signals gives:

- on entry: `LEVEL_TAGS == mergeTags(D, S_override)`;
- on exit: `LEVEL_TAGS == mergeTags(D, S_restored)`.

Applying PO-3 after either signal proves the visible `Message.level_tag`
behavior.

## K Artifacts

The formal core is:

- `fvk/mini-python-message-tags.k`
- `fvk/message-tags-spec.k`

These files model only the property-bearing fragment: settings tag map,
default tag map, `LEVEL_TAGS` contents, mapping identity, receiver action, and
level-tag lookup.

## Reproduce the Machine Check

The following commands are the expected K commands for an environment where K
is installed. They were not run in this workspace.

```sh
kompile fvk/mini-python-message-tags.k --backend haskell
kast --backend haskell fvk/message-tags-spec.k
kprove fvk/message-tags-spec.k
```

Expected result after successful machine checking: `#Top`.

## Test Redundancy Recommendation

No tests were read or modified as part of the repair. If public tests exist for
the in-domain point `MESSAGE_TAGS={50: 'critical'}` and
`Message(50, ...).level_tag == 'critical'`, those tests are subsumed by the
constructed proof only after `kprove` returns `#Top`. Until then, keep them.

Integration tests around middleware/storage wiring should be kept regardless,
because this proof covers tag-map refresh and lookup only.

## Residual Risk

- The proof is constructed, not machine-checked.
- The mini semantics is a property-complete abstraction, not full Python or
  full Django semantics.
- Termination is trivial for the audited straight-line receiver and lookup
  paths, but no whole-framework termination claim is made.
