# Proof Obligations

Status: constructed, not machine-checked.

## PO-001: normalize configured fixture entries before validation

Provenance: E1, E2.

For every configured fixture directory entry `e` in the verified domain, the
validation logic must compare `os.fspath(e)`, not raw object identity or raw
object equality.

V1 status: discharged by
`fixture_dirs = [os.fspath(fixture_dir) for fixture_dir in settings.FIXTURE_DIRS]`.

## PO-002: detect mixed string/path-like duplicates

Provenance: E1, E2, E5, E6.

For any path string `P`, a configured list containing both a string path `P`
and a path-like object whose filesystem string is `P` must raise the existing
duplicate `ImproperlyConfigured` error.

V1 status: discharged by PO-001 plus the existing
`len(fixture_dirs) != len(set(fixture_dirs))` check.

K claims: C1 and C2.

## PO-003: detect path-like app default fixture directory conflicts

Provenance: E5, E7.

For any app default fixture directory string `D`, a configured path-like entry
whose filesystem string is `D` must raise the existing default-directory
`ImproperlyConfigured` error, assuming the duplicate check did not already
raise.

V1 status: discharged because the app default string is compared with the
converted configured string list.

K claim: C3.

## PO-004: preserve valid path-like fixture directories

Provenance: E8.

A configured path-like directory with no duplicate and no default-directory
conflict must remain accepted.

V1 status: discharged because `os.fspath()` is the standard conversion used by
the later `os.path` operations, and no new rejection branch is introduced.

K claim: C4.

## PO-005: preserve public API and search-order compatibility

Provenance: E3, E4, E8.

The repair must not alter the `loaddata` command API, the `fixture_dirs`
property signature, exception classes/messages for the existing checks, or the
documented search locations.

V1 status: discharged by inspection. The edit is local to the value compared
inside existing validation branches.

## PO-006: realpath alias duplicate policy is outside the proven contract

Provenance: E10 and F-002.

The proof does not require detecting configured entries whose filesystem
strings differ but whose later `realpath()` values are equal.

V1 status: intentionally not discharged as a correctness obligation for this
issue because public intent is ambiguous. It is retained as future iteration
guidance, not as a reason to edit V1.
