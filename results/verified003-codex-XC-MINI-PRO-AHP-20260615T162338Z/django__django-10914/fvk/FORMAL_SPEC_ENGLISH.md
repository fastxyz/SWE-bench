# Formal Spec in English

Status: paraphrase of `fvk/upload-permissions-spec.k`.

## DEFAULT

`defaultUploadPermissions` evaluates to `mode(420)`, where decimal `420` is
octal `0o644`.

## TEMP-DEFAULT

For any pre-normalization temporary-path mode `TMP` and memory-path mode `MEM`,
`savedMode(temporary, defaultUploadPermissions, TMP, MEM)` evaluates to `420`.

## MEMORY-DEFAULT

For any pre-normalization temporary-path mode `TMP` and memory-path mode `MEM`,
`savedMode(memory, defaultUploadPermissions, TMP, MEM)` evaluates to `420`.

## TEMP-NONE

For explicit `None`, `savedMode(temporary, none, TMP, MEM)` evaluates to `TMP`.
This represents the previous behavior where Django skips final chmod and the
temporary-file path keeps its path-derived mode.

## MEMORY-NONE

For explicit `None`, `savedMode(memory, none, TMP, MEM)` evaluates to `MEM`.
This represents the previous behavior where Django skips final chmod and the
memory path keeps its creation/umask-derived mode.
