# FVK Spec

Status: constructed, not machine-checked.

## Target

The target property is dynamic message tag lookup under
`override_settings(MESSAGE_TAGS=...)`.

This spec covers the audited units:

- `utils.get_level_tags()`
- `storage.base.update_level_tags()`
- `Message.level_tag`

There are no loops or recursive functions in the audited change. The proof is
therefore a finite symbolic execution over map refresh and lookup operations.

## Public Intent Ledger

The public evidence ledger is in `fvk/PUBLIC_EVIDENCE_LEDGER.md` and is
mirrored here in summary:

- E1/E3: the issue requires `LEVEL_TAGS` to be refreshed by a
  `setting_changed` receiver when `MESSAGE_TAGS` changes.
- E2/E6: the public observable is `Message.level_tag`, which must return a
  configured tag instead of `''` for a configured custom level.
- E4/E5: `MESSAGE_TAGS` extends and overrides default message tags.
- E7: `override_settings()` sends `setting_changed` on both entry and exit.
- E8: the receiver belongs with the contrib messages code.
- E9: V1 rebinding fixed the main lookup but left a compatibility edge for
  direct references to the mapping object.

## Domain

Let:

- `D` be the default tag mapping from message levels to strings.
- `S` be the active `settings.MESSAGE_TAGS` mapping, or the empty map when the
  setting is absent.
- `mergeTags(D, S)` be the mapping produced by default tags extended by `S`,
  with `S` taking precedence for duplicate levels.
- `L` be any integer message level.
- `tagOf(T, L)` be `T[L]` when `L` is in `T`, otherwise `''`.

No additional precondition is imposed on `L`: Django message levels are
integers, and custom levels are also integers.

## Contract

C1. `get_level_tags()` returns `mergeTags(D, S)` for the active settings.

C2. On `setting_changed` where `setting == 'MESSAGE_TAGS'`,
`update_level_tags()` changes the contents of the existing `LEVEL_TAGS` map to
`mergeTags(D, S)` for the active settings.

C3. On `setting_changed` where `setting != 'MESSAGE_TAGS'`,
`update_level_tags()` leaves the contents of `LEVEL_TAGS` unchanged.

C4. `Message(level=L).level_tag` returns `tagOf(LEVEL_TAGS, L)`.

C5. Combining C2 and C4, after entering
`override_settings(MESSAGE_TAGS=S)`, `Message(level=L).level_tag` returns
`tagOf(mergeTags(D, S), L)`.

C6. Combining C2, C4, and Django's exit signal, after leaving the override,
`Message(level=L).level_tag` returns `tagOf(mergeTags(D, S0), L)`, where `S0`
is the restored settings map.

C7. The `LEVEL_TAGS` object identity is preserved by the refresh. This is a
compatibility strengthening derived from E1/E9, not a public documentation
requirement.

## Formal Artifacts

The mini semantics and claims are:

- `fvk/mini-python-message-tags.k`
- `fvk/message-tags-spec.k`

The commands that should be run in an environment with K installed are:

```sh
kompile fvk/mini-python-message-tags.k --backend haskell
kast --backend haskell fvk/message-tags-spec.k
kprove fvk/message-tags-spec.k
```

Expected result if the constructed claims are accepted by the K toolchain:
`#Top`. These commands were not run in this workspace.
