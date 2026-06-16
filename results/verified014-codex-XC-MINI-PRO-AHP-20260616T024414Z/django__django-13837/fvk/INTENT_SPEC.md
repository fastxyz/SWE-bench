# Intent Specification

Status: constructed from public evidence; not machine-checked.

## Target

`django.utils.autoreload.get_child_arguments()` constructs the argument vector
used by `restart_with_reloader()` to spawn the autoreload child process.

## Public Intent Obligations

I1. Package `-m` invocation is preserved.

For a Django management command reached through a package entry point, e.g.
`python -m pkg_other_than_django runserver`, the reloader child must be invoked
as `python -m pkg_other_than_django runserver`, with Python warning options
preserved before `-m`.

I2. Detection is package-agnostic.

The package name must come from the active top-level `__main__` module's
documented import metadata, not from a hard-coded comparison with Django's
`__main__` module.

I3. Detection does not require module `__file__`.

The `-m` decision must not depend on `django.__main__.__file__` or on any
entry-point module having `__file__`.

I4. Directory and zipfile execution are not treated as `-m <package>`.

The issue states that those entry forms have an empty `__main__.__spec__.parent`;
an empty parent must therefore fall through to the existing script/fallback
logic.

I5. Existing non-`-m` behavior is preserved.

When no non-empty `__main__.__spec__.parent` exists, the function keeps the
existing behavior for script paths, Windows `.exe` entrypoint fallback,
`-script.py` fallback, warning options, and missing-script `RuntimeError`.

## Domain

The package-preservation contract covers complete Python programs whose
top-level `__main__` module has `__spec__.parent == P` for a non-empty package
name `P`. The FVK model treats `P == ""` and missing spec/parent as the same
non-package branch because both are falsy in the candidate Python code and both
are outside the package `-m` obligation.

No termination proof is needed for `get_child_arguments()` because the modeled
function has finite branch structure and no loops. `restart_with_reloader()`
contains an intentional loop around subprocess restarts, but the changed
observable is the argument vector obtained before that loop.
