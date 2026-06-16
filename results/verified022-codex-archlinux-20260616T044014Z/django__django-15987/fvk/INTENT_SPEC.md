# Intent Specification

Status: constructed from public evidence only.

## Target

`django.core.management.commands.loaddata.Command.fixture_dirs`.

The audited behavior is the validation of `settings.FIXTURE_DIRS` before
`loaddata` searches fixture files.

## Required behavior

1. `FIXTURE_DIRS` entries may include path-like objects, including
   `pathlib.Path` instances, when they name fixture directories.
2. The duplicate check in `loaddata` must detect duplicate fixture directories
   even when one or more configured entries are path-like objects.
3. Duplicate configured fixture directories must raise
   `ImproperlyConfigured("settings.FIXTURE_DIRS contains duplicates.")`.
4. A configured fixture directory that is also an application's default
   `fixtures` directory must raise the existing default-directory
   `ImproperlyConfigured` error.
5. Nonduplicate path-like fixture directories must remain loadable and must not
   be rejected merely because they are path-like objects.
6. The fix must not change the public command API, test files, or the
   high-level search order documented for `loaddata`.

## Domain

The verified domain is finite `FIXTURE_DIRS` sequences whose entries are
strings or `os.PathLike`-compatible path objects whose `os.fspath()` result is
a string path. App default fixture directories are modeled as string paths,
matching the implementation's `os.path.join(app_config.path, "fixtures")`.

## Explicitly not settled by public intent

The available issue text requires fixing path-like object comparison. It does
not clearly require changing the older behavior for path aliases whose
`os.fspath()` strings differ but whose `os.path.realpath()` values later
collapse to the same directory, such as symlink or relative-path aliases.
That broader canonicalization question is recorded as an ambiguous finding
rather than used to justify a source change.
