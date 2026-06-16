# Baseline Notes

## Root Cause

The conftest import path was canonicalized by `_pytest.pathlib.unique_path()` using
`os.path.normcase(str(path.realpath()))`. On Windows, `normcase()` lowercases the
entire path. That lowercased path was not only used as a cache identity: it was
also passed on to `py.path.local.pyimport()` in `_importconftest()`.

When a project or package directory contains uppercase characters, the lowered
path can produce a lowered module name during import, such as
`python.pisys.conftest` instead of the case stored on disk. Python's import
machinery can reject that module name on Windows, leading to
`ModuleNotFoundError` while loading `conftest.py`.

## Files Changed

`repo/src/_pytest/pathlib.py`

Changed `unique_path()` to canonicalize through `Path.resolve()` and convert the
resolved path back to the original path type. This keeps the existing intent of
resolving symlinks and obtaining a canonical path for `py.path.local`, while
preserving the filesystem casing needed by `pyimport()`. The unused `normcase`
import was removed.

## Assumptions

`Path.resolve()` is the appropriate canonicalization primitive here because the
existing helper's docstring already states that `pathlib.Path` handles this
natively, and the public issue discussion points to preserving correct casing
rather than lowercasing.

The fix should remain at the shared `unique_path()` helper instead of only in
`_importconftest()`, because all current runtime callers use the helper for
conftest discovery/import identity and should agree on the same canonical,
case-preserving path.

## Alternatives Considered

Keeping `normcase()` for cache keys while importing with a separate original
path was rejected because it would leave `unique_path()` returning a value that
contradicts its case-preserving contract and would require extra split-key logic
in conftest import code.

Removing canonicalization entirely and returning `path.realpath()` was rejected
because the existing helper also protects symlinked conftest handling and
wrong-cased Windows working directories. Using `Path.resolve()` keeps that
canonicalization step without forcing lowercase import names.

No tests or project code were run, per the task instructions.
