# Baseline Notes

## Root Cause

Django's autoreloader restarts the development server by building a new child
process command in `django.utils.autoreload.get_child_arguments()`. That command
already preserved warning options from `sys.warnoptions`, but it didn't preserve
CPython `-X` options. Since interpreter options aren't included in `sys.argv`,
the reloader child process lost options such as `-X utf8`, which could change
runtime behavior after the first reload-spawned process.

## Changed Files

`repo/django/utils/autoreload.py`

Added CPython implementation option propagation when constructing the child
process arguments. The code now reads `sys._xoptions` when available and formats
each option back into a `-X...` interpreter argument, preserving both flag-style
options and `name=value` options before appending the module or script arguments.

## Assumptions and Alternatives Considered

I assumed `sys._xoptions` is the authoritative in-process source for `-X`
options because `sys.argv` omits interpreter flags and the issue references
CPython's documented `_xoptions` behavior.

I preserved options generically instead of special-casing `utf8`, because the
autoreloader should keep the child interpreter consistent for any CPython
implementation option, including options with explicit values.

I used `hasattr(sys, '_xoptions')` rather than hard-coding a CPython-only branch
so the change remains harmless on interpreters that don't expose `_xoptions`
while still preserving options when the current interpreter provides them.

I did not change the executable-entrypoint fallback that directly runs a
Windows `.exe` shim, because that path intentionally bypasses `sys.executable`
and already cannot accept Python interpreter flags such as `-W` or `-X`.
