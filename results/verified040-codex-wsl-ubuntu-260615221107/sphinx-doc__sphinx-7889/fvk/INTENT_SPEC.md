# Intent Spec

Constructed before accepting V1 behavior as the expected result.

## Public Intent Obligations

1. Autodoc mock imports must allow documentation builds to continue when code
   uses generic-typed classes.
2. `_make_subclass()` must not raise `TypeError` by attempting to concatenate a
   `str` with a `TypeVar` or another non-string generic parameter.
3. Existing mock attribute behavior remains in scope: string attribute names
   produce mock objects with dotted display names such as
   `mocked_module.some_attr`.
4. Generic subscription is in domain for ordinary Python generic parameters,
   including `typing.TypeVar` and class/type objects. The issue does not require
   defining a semantically precise runtime generic alias; it requires avoiding
   the mock-layer crash so autodoc can proceed.

## Default-Domain Assumptions

- Python `TypeVar` objects expose a string `__name__`.
- Python `repr()` returns a string for ordinary objects used as generic
  parameters. Objects whose `__repr__` itself raises or returns a non-string are
  outside the public issue's domain.
- The existing dotted mock display-name convention is preserved unless public
  intent requires a bracketed generic display; no such public evidence was found.
