# Baseline Notes

## Root cause

`MigrationLoader.load_disk()` successfully imported a migrations module, then
classified it as unmigrated when the imported module did not expose `__file__`.
That was valid when migration discovery depended on filesystem access through
`__file__`, but discovery now uses `pkgutil.iter_modules(module.__path__)`.
Implicit namespace packages, including migrations directories without
`__init__.py`, expose `__path__` but may not expose `__file__`, so the loader
skipped valid migration packages before discovery could run.

## Changed files

`repo/django/db/migrations/loader.py`

Removed the `__file__ is None` check from `MigrationLoader.load_disk()`. The
loader still rejects modules that are not packages by requiring `__path__`, but
namespace packages with `__path__` now reach the existing `pkgutil.iter_modules()`
discovery path.

## Assumptions and alternatives

I assumed the intended behavior is for namespace migrations packages to be
treated the same as regular migrations packages: if the module imports and has
`__path__`, it is a valid package for discovery, even if it has no `__file__`.

I considered adding a special branch for namespace packages, but rejected it
because the current discovery code already works from `module.__path__`; keeping
one package path avoids duplicating migration discovery behavior.

I also considered changing migration writer or questioner code. The writer
already falls back to app-relative paths when a module directory cannot be
resolved, and the questioner already handles `__path__` for modules without
`__file__`, so the issue described here is isolated to the loader.

No tests or project code were run, per the task constraints.
