# Baseline Notes

## Root cause

`MigrationLoader.load_disk()` treated an imported migrations module with no
`__file__` attribute as an empty namespace package and marked the app as
unmigrated. Python's import API allows ordinary packages to omit `__file__`,
which can happen in frozen environments. Those packages still expose a normal
list-valued `__path__`, so the loader was rejecting valid migrations before
calling `pkgutil.iter_modules()`.

## Files changed

`repo/django/db/migrations/loader.py`

The namespace-package guard now marks a migrations module as unmigrated only
when `__file__` is missing and `__path__` is not a list. This preserves the
existing rejection of PEP 420 namespace packages while allowing regular
packages without `__file__` to proceed through the existing package check and
module discovery.

## Assumptions and alternatives

I assumed the requested behavior is limited to migration loading and should not
change broader module path handling elsewhere in Django.

I considered removing the `__file__` check entirely, but rejected that because
the loader still needs to treat namespace-only migration directories as
unmigrated. I also considered moving the `hasattr(module, '__path__')` check
before the namespace check, but using `getattr(module, '__path__', None)` keeps
the existing behavior for non-package modules without adding extra control
flow.
