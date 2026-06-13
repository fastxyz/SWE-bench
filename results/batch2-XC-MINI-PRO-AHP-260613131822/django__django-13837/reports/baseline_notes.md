# Baseline notes — django__django-13837

## Issue

Allow autoreloading of `python -m pkg_other_than_django runserver`.

`django.utils.autoreload.get_child_arguments()` is responsible for reconstructing the
command line that the autoreloader uses to restart the development server in a child
process. It needs to detect whether Python was originally launched with the `-m`
(run-module) option so that the child is launched the same way.

The old implementation only recognized the single special case `python -m django` and,
in doing so, relied on module `__file__` attributes which are not present in every
Python environment.

## Root cause

```python
import django.__main__
django_main_path = Path(django.__main__.__file__)
py_script = Path(sys.argv[0])

args = [sys.executable] + ['-W%s' % o for o in sys.warnoptions]
if py_script == django_main_path:
    # The server was started with `python -m django runserver`.
    args += ['-m', 'django']
    args += sys.argv[1:]
```

Two problems:

1. **Hard-coded to `django`.** The detection compares `sys.argv[0]` against the path of
   `django/__main__.py`. Any other package launched via `python -m mypkg runserver`
   (e.g. a Django-based CLI that ships its own `__main__` and overrides `runserver`)
   is not recognized, so the child process is restarted as a plain script invocation
   instead of `-m mypkg`, breaking the `-m` semantics.

2. **Depends on `__file__`.** Building `django_main_path` from `django.__main__.__file__`
   assumes modules expose `__file__`. That is not guaranteed in all environments
   (frozen apps, some embedded/zipped setups), so the detection can fail or raise.

## Fix

File changed: `repo/django/utils/autoreload.py`, function `get_child_arguments()`.

Use Python's documented `__main__.__spec__` to detect the `-m` launch instead of a
path comparison:

```python
import __main__
py_script = Path(sys.argv[0])

args = [sys.executable] + ['-W%s' % o for o in sys.warnoptions]
# __spec__ is set when the server was started with the `-m` option,
# see https://docs.python.org/3/reference/import.html#main-spec
# __spec__ may not exist, e.g. when running in a Conda env.
if getattr(__main__, '__spec__', None) is not None and __main__.__spec__.parent:
    args += ['-m', __main__.__spec__.parent]
    args += sys.argv[1:]
```

Why this is correct (per the Python docs and the issue):

- `__main__.__spec__` is `None` when Python is started with a *script path*
  (e.g. `python manage.py runserver`) — those launches fall through to the existing
  Windows/`sys.argv` handling unchanged.
- `__main__.__spec__` is **not** `None` when Python is launched with `-m`, **or** with
  the name of a directory / zipfile / other `sys.path` entry.
- In the directory/zipfile case, `__main__.__spec__.parent` is the empty string
  (falsy), so the guard `and __main__.__spec__.parent` correctly excludes it — those
  launches already carry the runnable path in `sys.argv[0]` and should not be turned
  into `-m`.
- In the `-m pkg` case (package with a `__main__` submodule), `__main__.__spec__.parent`
  equals `"pkg"`, so the child is restarted as `python -m pkg <args>` for *any* package,
  not just `django`.

This also removes the reliance on `__file__` and the now-unneeded import of
`django.__main__` inside the function (the top-level `import django` used by
`is_django_path()` is untouched). I verified no other code references
`django_main_path` or `django.__main__`.

## Behavior matrix after the fix

| Launch                                   | `__spec__`     | `__spec__.parent` | Child args            |
|------------------------------------------|----------------|-------------------|-----------------------|
| `python -m django runserver`             | not None       | `"django"`        | `-m django ...`       |
| `python -m mypkg runserver`              | not None       | `"mypkg"`         | `-m mypkg ...`        |
| `python manage.py runserver`             | None           | —                 | unchanged (`sys.argv`)|
| `python somedir/ runserver` / zipfile    | not None       | `""` (empty)      | unchanged (`sys.argv`)|

## Assumptions / alternatives considered and rejected

- **Keep the special-case path comparison but also accept other packages.** Rejected:
  it would still depend on each package exposing `__file__` and on enumerating package
  main paths. `__spec__` is the documented, environment-independent mechanism.
- **Use `__main__.__package__` instead of `__main__.__spec__.parent`.** The issue notes
  `__spec__.parent` is *usually* but not always equal to `__package__`; `__spec__.parent`
  is the authoritative value, so I used it.
- **Handling `python -m pkg.module` where `module` is a plain module (not a package).**
  Here `__spec__.parent` is the containing package `pkg`, not `pkg.module`. This is an
  inherent edge case of `-m` plus a non-package module and is consistent with the
  documented `__spec__` semantics described in the issue; the targeted use case
  (`python -m pkg runserver` with a `__main__` submodule) is handled correctly. No extra
  special-casing was added so the change stays minimal.
