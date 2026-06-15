# Baseline Notes

## Root cause

`quantity_input` treated every non-empty return annotation as a unit target and
unconditionally called `.to(...)` on the wrapped function's return value. For a
constructor annotated as `-> None`, `inspect.signature` exposes the annotation as
`None`, but `None` is a Python type hint meaning "no return value", not an
Astropy unit. Since `__init__` returns `None`, the wrapper attempted
`None.to(None)` and raised `AttributeError`.

## Changed files

- `repo/astropy/units/decorators.py`: stored the return annotation in a local
  variable and skipped unit conversion when the annotation is exactly `None`.
  Unit return annotations such as `-> u.deg` still follow the existing
  conversion path.

## Assumptions and alternatives

- I assumed `-> None` should be interpreted as a standard Python no-return type
  annotation, so the decorator should leave the actual return value unchanged.
- I considered skipping conversion whenever the wrapped function returns
  `None`, regardless of the return annotation. I rejected that because it would
  also hide mistakes where a function annotated with a unit target accidentally
  returns `None`.
- I did not modify tests, and I did not run tests or code in this environment.
