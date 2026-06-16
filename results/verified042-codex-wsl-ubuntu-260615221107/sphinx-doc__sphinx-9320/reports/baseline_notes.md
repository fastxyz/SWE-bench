# Baseline Notes

## Root cause

`sphinx.cmd.quickstart.ask_user()` detected an existing `conf.py` in the selected
root path, printed an overwrite warning, and then prompted for a replacement path
with the message "or just Enter to exit". That prompt still used the `is_path`
validator, which rejects an empty string before the subsequent `if not d['path']`
exit branch can run. Pressing Enter therefore reported "Please enter a valid path
name" instead of exiting.

## Files changed

`repo/sphinx/cmd/quickstart.py`

- Replaced the existing-project retry loop with a direct status-1 exit after the
  existing `conf.py` warning. This matches the public issue hint that quickstart
  should fail immediately when the selected root already contains a Sphinx
  project, and it removes the unreachable empty-input exit path.
- Added handling in `main()` for `SystemExit` raised during interactive prompting
  so callers of `main()` receive the integer status code consistently and
  generation is skipped after the existing-project error.

## Assumptions and rejected alternatives

- I assumed "selected root path" includes both `conf.py` directly under the root
  and `source/conf.py`, because the existing guard already checked both layouts.
- I considered adding a new validator that permits an empty replacement path.
  That would make the old "Enter to exit" branch reachable, but it would preserve
  the extra retry prompt despite the public hint that an already-selected Sphinx
  project should fail immediately.
- I did not alter quiet-mode validation because it already returns status 1 for
  non-empty/reserved target directories and is not part of the interactive prompt
  failure.
