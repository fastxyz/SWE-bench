# Formal Spec in English

Status: paraphrase of the K claims in `loaddata-fixture-dirs-spec.k`.

## Claim C1: mixed string and Path duplicate

For every path string `P`, if `FIXTURE_DIRS` contains both `StrPath(P)` and
`PathObj(P)`, then running the fixture-directory validation reaches
`DuplicateError`.

## Claim C2: reversed mixed Path and string duplicate

For every path string `P`, if `FIXTURE_DIRS` contains both `PathObj(P)` and
`StrPath(P)`, then running the fixture-directory validation reaches
`DuplicateError`.

## Claim C3: Path default fixture directory

For every app default fixture directory string `D`, if a path-like configured
entry has filesystem string `D`, and the configured entries are not otherwise
duplicates, then validation reaches `DefaultFixtureDirError(D)`.

## Claim C4: nonduplicate Path entry is preserved

For every path string `P`, if a path-like configured entry has filesystem
string `P`, the converted configured list has no duplicates, and no app default
fixture directory equals `P`, then validation reaches `Ok(...)` with `P` in the
converted configured list.

## Claim C5: duplicate check uses filesystem strings

The helper `fspath(PathObj(P))` rewrites to the same string `P` as
`fspath(StrPath(P))`. All duplicate and default-directory checks operate on the
converted string list, not on raw path-object identity.

## Side conditions

The claims are partial-correctness claims over finite configured-directory
lists. They do not prove filesystem existence, filesystem symlink behavior,
termination of Django app iteration, database fixture loading, or
`os.path.realpath()` canonical-alias duplicate detection.
