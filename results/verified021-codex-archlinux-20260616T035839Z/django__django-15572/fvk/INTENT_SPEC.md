# Intent Spec

Status: constructed from public issue text and source inspection; no code or tests
were executed.

## Required behavior

IS1. An empty string in Django template `DIRS` is an invalid value, but it must
not cause autoreload to treat the project working directory as a template
directory.

IS2. The compatibility target is the pre-regression behavior described in the
issue: an empty string should not match a real template directory for
autoreload purposes.

IS3. The fix must cover all contributors to `get_template_directories()`:
configured `backend.engine.dirs` and loader-provided `get_dirs()` values.

IS4. Valid non-empty configured template directories remain normalized to
`Path` values relative to `Path.cwd()` for relative paths, preserving the
behavior introduced by the path normalization change.

IS5. Loader-provided Django-internal template directories remain filtered by
`is_django_path()`.

IS6. The issue only identifies the string value `""` as the accidental current
directory contributor. Explicit current-directory values such as `"."` or
`Path(".")` are not part of the reported regression and must not be silently
removed by this fix.

