# Proof Obligations

Status: constructed, not machine-checked.

## PO-1 - Type Preservation

For all in-domain path objects `p`, `type(unique_path(p)) == type(p)`.

Source: E9 and current caller expectations.

V1 discharge: the implementation returns `type(path)(...)`.

## PO-2 - Case-Preserving Canonicalization

For all existing filesystem paths `p` used by conftest loading,
`str(Path(str(p)).resolve())` is a canonical path string whose components match
the filesystem's stored casing.

Source: E1, E3, E4, E5, E7.

V1 discharge: source uses `Path(str(path)).resolve()` and no longer calls
`normcase()`.

Residual status: external filesystem/pathlib trusted-base obligation, not
machine-proved here.

## PO-3 - Import Path Uses Preserved Case

When `_importconftest(conftestpath)` misses the cache, the path passed to
`conftestpath.pyimport()` must be the canonical case-preserving path from PO-2.

Source: E1, E2, E4, E5.

V1 discharge: `_importconftest()` assigns `conftestpath = unique_path(conftestpath)`
before `pypkgpath()` and `pyimport()`, and V1's `unique_path()` has no
lowercasing step.

## PO-4 - Same-File Alias Uniqueness

If two in-domain paths refer to the same filesystem entry through a symlink or
case alias, then `unique_path()` returns equal path strings for them.

Source: E6, E8.

V1 discharge: `Path.resolve()` is the canonicalizer in the helper; alias
uniqueness is part of the external canonicalization obligation.

## PO-5 - Conftest Cache Consistency

The dictionaries `_conftestpath2mod` and `_dirpath2confmods` continue to use the
same canonical representation that conftest import uses.

Source: E6, E8 and code callers.

V1 discharge: all runtime uses still call the shared `unique_path()` helper.

## PO-6 - Public Compatibility

The patch must not alter the `unique_path(path)` signature, return family, or
conftest caller protocol.

Source: E9.

V1 discharge: signature unchanged; result construction remains `type(path)(...)`.

## PO-7 - Honesty Boundary

The constructed K claims must not be reported as machine-checked because K tools
were not run.

Source: FVK instructions and task restrictions.

V1/FVK discharge: all proof artifacts are labeled "constructed, not
machine-checked", and test removal is not recommended.
