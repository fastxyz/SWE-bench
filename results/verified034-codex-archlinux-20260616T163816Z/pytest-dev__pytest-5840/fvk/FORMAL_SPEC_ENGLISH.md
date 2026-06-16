# Formal Spec English

This paraphrases the K claims in `unique-path-spec.k`.

## Claim UNIQUE-PATH-PRESERVES-CASE

For any existing filesystem path represented as `path(T, S)`, executing
`uniquePath(path(T, S))` returns `path(T, resolveCanon(S, FS))`. The returned
object has the same path type `T` as the input. Under the external filesystem
axioms for `resolveCanon`, the resolved string preserves filesystem casing and
names the same filesystem entry as `S`.

## Claim UNIQUE-PATH-ALIASES

For any two existing path strings `S1` and `S2` that name the same filesystem
entry, `uniquePath(path(T, S1))` and `uniquePath(path(T, S2))` return path
objects with the same canonical string. This is the conftest cache-key
obligation for symlinks and case aliases.

## Claim IMPORT-CONFTEST-PATH

The conftest import flow first canonicalizes the conftest path with
`uniquePath`. Therefore, under the resolved-case obligation, the path passed to
`pyimport()` is canonical and case-preserving. The pre-fix lowercased module-name
failure is excluded because the model has no `normcase` transition.

## Frame Conditions

The function signature remains `unique_path(path)`. The result remains an
instance of `type(path)`. No conftest caller receives a new return shape or needs
a new argument.
