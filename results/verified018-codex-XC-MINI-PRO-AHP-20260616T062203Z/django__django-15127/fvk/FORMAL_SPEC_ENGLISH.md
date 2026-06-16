# Formal Spec English

Status: constructed, not machine-checked.

This file paraphrases every nontrivial formal claim from
`fvk/message-tags-spec.k`.

## Claim `update-message-tags`

For any active settings tag map `S`, default tag map `D`, existing
`LEVEL_TAGS` contents `T`, and mapping object identity `OID`, executing the
receiver action for `setting == 'MESSAGE_TAGS'` terminates with:

- `LEVEL_TAGS` contents equal to `mergeTags(D, S)`;
- the same `LEVEL_TAGS` object identity `OID`;
- all other modeled cells unchanged.

## Claim `ignore-other-setting`

For any setting name other than `MESSAGE_TAGS`, executing the receiver action
terminates with the existing `LEVEL_TAGS` contents unchanged and the same
mapping object identity.

## Claim `message-level-tag-after-update`

For any integer message level `L`, after a `MESSAGE_TAGS` receiver action and
then a `Message.level_tag` lookup, the result is
`tagOf(mergeTags(D, S), L)`: the configured tag when `L` is configured in
`S`, the default tag when only the default map has `L`, and `''` when neither
map has `L`.

## Claim `message-level-tag-current-map`

For any integer message level `L`, a `Message.level_tag` lookup over the
current `LEVEL_TAGS` map returns `tagOf(LEVEL_TAGS, L)`.

## Claim `restore-after-exit`

If `override_settings()` exits and the active settings tag map is restored to
`S0`, the same `MESSAGE_TAGS` receiver action refreshes `LEVEL_TAGS` to
`mergeTags(D, S0)`. A following `Message.level_tag` lookup returns
`tagOf(mergeTags(D, S0), L)`.
