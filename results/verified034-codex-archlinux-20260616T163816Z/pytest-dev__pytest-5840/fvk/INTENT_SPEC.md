# Intent Spec

Status: constructed from public evidence only; no tests, Python, or K tooling were
run.

## Required Behavior

1. Conftest paths used for import must preserve the filesystem casing of every
   package/module path component. A path such as `muepy/imageProcessing/...` must
   not become `muepy/imageprocessing/...` before `pyimport()` computes the module
   name.

2. `unique_path(path)` must still return a canonical path for `py.path.local`
   callers so conftest discovery treats case aliases and symlink aliases of the
   same filesystem entry as the same conftest.

3. `unique_path(path)` must preserve the input path object family by returning
   `type(path)(...)`; callers that store or compare `py.path.local` values must
   continue to receive `py.path.local`.

4. The public call surface must remain unchanged. The fix must not require a new
   argument, new return shape, or changes to tests/plugins calling conftest
   discovery.

## Domain

The in-domain paths are existing filesystem entries used by conftest loading:
existing directories passed through initial conftest discovery, existing
`conftest.py` files found by `isfile()`, and existing `--confcutdir`
directories accepted by `directory_arg`.

The formal model assumes the platform/path library operation corresponding to
`Path(str(path)).resolve()` returns a canonical, symlink-resolved path with
filesystem casing preserved for existing entries. That external filesystem
behavior is a proof obligation, not something this mini semantics can derive.
