# Baseline Notes

## Root cause

`django/core/management/commands/loaddata.py` read `settings.FIXTURE_DIRS`
directly when checking for duplicate fixture directories and for directories
that duplicate an app's default `fixtures` directory. Since `pathlib.Path`
instances don't compare equal to their equivalent string paths, a mixed
configuration such as `Path("/path/to/fixtures")` and `"/path/to/fixtures"`
could bypass the duplicate check even though both entries resolve to the same
directory.

## Changed files

`repo/django/core/management/commands/loaddata.py`

Converted each entry in `settings.FIXTURE_DIRS` with `os.fspath()` before the
existing duplicate and default-directory checks run. This keeps the existing
validation flow and final `realpath()` behavior intact while making path-like
objects comparable with string paths.

## Assumptions and alternatives

I assumed the intended behavior is that `FIXTURE_DIRS` may contain path-like
objects, but validation should treat a path-like object and the same path as a
string as the same configured directory.

I considered moving the duplicate check after `os.path.realpath()` normalization
so it would also catch symlink or relative-path aliases. I rejected that broader
change because the reported issue is specifically about `Path` instances, and
changing duplicate detection semantics for all path aliases could affect
existing configurations beyond the issue's scope.

I did not modify tests, per the task instructions.
