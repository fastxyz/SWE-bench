# Baseline Notes

## Root Cause

`pylint.config` defaulted `PYLINT_HOME` to `~/.pylint.d` whenever the user's home directory was discoverable. That puts persistent run stats directly under `$HOME` and does not honor the XDG Base Directory Specification. The same code created the directory with `os.mkdir`, which only works for a single missing path component and is not reliable for an XDG-style default such as `~/.cache/pylint` when `~/.cache` does not already exist.

## Changed Files

`repo/pylint/config/__init__.py`

- Added `_get_default_pylint_home()` so the default persistent-data location is derived from `XDG_CACHE_HOME` when it is set to an absolute path, or from `~/.cache/pylint` otherwise.
- Preserved `PYLINTHOME` as an explicit override and preserved the existing `.pylint.d` fallback when the user home directory cannot be resolved.
- Changed directory creation from `os.mkdir` to `os.makedirs` so nested XDG cache paths can be created.
- Updated the environment-help text to describe the new default.

## Assumptions And Alternatives

- I treated Pylint's stored `.stats` pickle files as cache data rather than user data because they are derived from lint runs and can be regenerated. That is why the default uses `XDG_CACHE_HOME` / `~/.cache/pylint` instead of `XDG_DATA_HOME` / `~/.local/share/pylint`.
- I did not add an `appdirs` or `platformdirs` dependency. The issue can be fixed with a small standard-library helper, and adding a runtime dependency would be a broader packaging change.
- I considered honoring relative `XDG_CACHE_HOME` values, but the XDG specification requires base-directory environment variables to be absolute paths. Relative values are ignored and the default falls back to `~/.cache`.
- I did not change configuration-file discovery. The issue is about the persistent stats directory, while pylintrc lookup already has separate documented behavior.
