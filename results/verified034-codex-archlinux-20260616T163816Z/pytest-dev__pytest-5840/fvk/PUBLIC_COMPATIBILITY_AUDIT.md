# Public Compatibility Audit

## Changed Symbol

`_pytest.pathlib.unique_path(path)`

## Signature

Unchanged: one positional argument, `path`.

## Return Shape

Preserved: V1 still returns `type(path)(...)`. Runtime conftest callers continue
to receive `py.path.local` when they pass `py.path.local`.

## Public Callers

`repo/src/_pytest/config/__init__.py`

- `_set_initial_conftests()` stores `_confcutdir = unique_path(...)`.
- `_getconftestmodules()` stores `_dirpath2confmods[unique_path(directory)]`.
- `_importconftest()` stores and looks up `_conftestpath2mod[unique_path(conftestpath)]` and passes that same value to `pyimport()`.

No caller requires a changed signature or return type.

## Public/In-Repo Test Callers

`repo/testing/test_conftest.py` imports `unique_path` and compares returned path
objects/strings. The V1 return type and path-string shape remain compatible with
those uses, while the string is no longer forcibly lowercased on Windows.

## Verdict

Compatible. No production caller, public helper use, subclass override, or
virtual dispatch path needs a source edit beyond V1.
