# Constructed Proof

Status: constructed, not machine-checked. Per the task instructions, no
Python, tests, `kompile`, or `kprove` commands were run.

## Machine-check commands to run later

From the workspace root:

```sh
cd fvk
kompile mini-python-paths.k --backend haskell
kast --backend haskell loaddata-fixture-dirs-spec.k
kprove loaddata-fixture-dirs-spec.k
```

Expected machine-check result after a real K run: `#Top` for all claims.

## Semantics summary

`mini-python-paths.k` models the relevant reduced behavior of
`Command.fixture_dirs`:

- `StrPath(P)` models a configured string path.
- `PathObj(P)` models a configured path-like object whose `os.fspath()` value
  is `P`.
- `fspaths(entries)` maps all configured entries to strings before validation.
- `validate(fs, appdirs)` checks configured duplicates first, then app default
  fixture directory conflicts, then accepts with `Ok(fs)`.

This fragment is intentionally smaller than full Python. It preserves the
property axis under verification: whether path-like and string representations
with the same filesystem string are compared as duplicates.

## Proof of C1 and C2

For C1, start with:

`fixtureDirs(Entry(StrPath(P), Entry(PathObj(P), REST)), APPDIRS)`.

By the `fixtureDirs` rule, this rewrites to:

`validate(fspaths(Entry(StrPath(P), Entry(PathObj(P), REST))), APPDIRS)`.

By the `fspaths` and `fspath` rules, `StrPath(P)` and `PathObj(P)` both become
the same string `P`, so the configured string list begins:

`SCons(P, SCons(P, fspaths(REST)))`.

`contains(P, SCons(P, fspaths(REST)))` rewrites to `true`, so
`hasDuplicate(SCons(P, SCons(P, fspaths(REST))))` rewrites to `true`.
The first `validate` rule therefore rewrites to `DuplicateError`.

C2 is the same derivation with the first two raw entries reversed. Both entries
still map to the same leading duplicated string pair after `fspaths`.

## Proof of C3

Start with:

`fixtureDirs(Entry(PathObj(D), REST), SCons(D, APPREST))`.

`fixtureDirs` and `fspaths` rewrite the configured entries to:

`SCons(D, fspaths(REST))`.

The claim requires this converted configured list to have no duplicate, so the
duplicate `validate` rule is not applicable. Validation proceeds to
`validateDefault(FS, firstIntersection(SCons(D, APPREST), FS))`.

Since `contains(D, FS)` is true for `FS = SCons(D, fspaths(REST))`,
`firstIntersection(...)` rewrites to `Some(D)`. `validateDefault(FS, Some(D))`
then rewrites to `DefaultFixtureDirError(D)`.

## Proof of C4

Start with a path-like configured entry `PathObj(P)` and side conditions that
the converted configured list has no duplicates and no app default fixture
directory intersects it.

`fixtureDirs` and `fspaths` rewrite the configured entries to
`SCons(P, fspaths(REST))`. The no-duplicate side condition excludes the
duplicate-error branch. The no-intersection side condition makes
`firstIntersection(APPDIRS, SCons(P, fspaths(REST)))` rewrite to `None`.
`validateDefault(FS, None)` rewrites to `Ok(FS)`, preserving `P` in the
accepted configured list.

## Obligations discharged

- PO-001: `fspath` is applied before validation in the semantics and in V1.
- PO-002: mixed path-like/string duplicates reduce to duplicate strings.
- PO-003: path-like default fixture directory conflicts are detected after
  conversion.
- PO-004: nonduplicate path-like entries remain accepted.
- PO-005: no public signature or command API changed.

## Residual risk

This is partial correctness over the reduced fixture-directory validation
fragment. It does not prove termination of Django app iteration, database
fixture loading, filesystem behavior, or the broader realpath-alias policy in
F-002.

The proof is constructed only. Test removal is not recommended in this
workspace because the proof has not been machine-checked and the public tests
exercise integration behavior beyond the reduced model.

## Test recommendation

Do not delete tests. Keep the existing duplicate, default fixture path, and
pathlib fixture directory tests. If machine-checking is later allowed and a
targeted unit test is added for mixed Path/string duplicates, only the pure
normalization assertion would be proof-subsumed; command-level integration
tests should remain.
