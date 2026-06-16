# Baseline Notes

## Root cause

`django.template.autoreload.get_template_directories()` normalizes configured
template directories by converting each value with `to_path()` and joining it to
`Path.cwd()`. An invalid configured directory of `""` is converted by
`pathlib.Path` into `Path(".")`, so the autoreloader treats the project working
directory as a template directory. `template_changed()` then regards unrelated
non-Python files under the project as template changes, returns `True`, and
prevents the normal autoreload path from running for those changes.

The same value can enter `get_template_directories()` directly through
`backend.engine.dirs` and indirectly through loaders exposing `get_dirs()`, so
both paths need the same handling.

## Changed files

`repo/django/template/autoreload.py`

Filtered out the empty string before template directory normalization in both
`backend.engine.dirs` and loader `get_dirs()` values. This preserves the
existing normalization behavior for valid relative paths, absolute paths, and
`Path` objects, while preventing an accidental empty string from becoming the
current working directory.

`reports/baseline_notes.md`

Recorded the cause of the regression, the source change, and the assumptions
behind the targeted fix.

## Assumptions and alternatives considered

I assumed the intended compatibility behavior is to ignore the invalid empty
string for autoreload purposes, matching the pre-normalization behavior where an
empty string would not match a real template directory.

I did not filter all falsey values because that would silently hide invalid
configuration such as `None`; the existing type validation should still surface
those errors.

I did not filter `Path(".")` or other explicit current-directory paths because
those can be intentional template directory settings. The reported regression is
specific to `""` being normalized into the current directory.

I did not add validation or existence checks for template directories because
the existing autoreload code records configured directories whether or not they
currently exist, and broader validation would change behavior outside the
reported issue.
