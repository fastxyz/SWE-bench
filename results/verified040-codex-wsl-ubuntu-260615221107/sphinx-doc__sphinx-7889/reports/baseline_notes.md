# Baseline Notes

## Root Cause

`sphinx.ext.autodoc.mock._MockObject.__getitem__()` forwarded its subscript key
directly to `_make_subclass()`. `_make_subclass()` annotated and treated that
value as a string, using it both in `module + '.' + name` and as the first
argument to `type()`.

That is valid for attribute names and string subscripts, but generic
parameterization can pass non-string objects such as `typing.TypeVar` instances
or builtin classes. When a mocked imported class is used as `MockedClass[T]`,
the mock layer tries to concatenate the display module string with the
`TypeVar`, raising `TypeError` before autodoc can continue.

## Changed Files

`repo/sphinx/ext/autodoc/mock.py`

- Changed `_MockObject.__getitem__()` to accept `Any`, matching the runtime
  behavior of Python subscripting.
- Changed `_make_subclass()` to accept `Any` for `name` and normalize the value
  before constructing `__display_name__` or calling `type()`.
- Added `_make_subclass_name()` to preserve existing string-name behavior while
  converting non-string generic parameters to stable class/display names. It
  uses `__name__` when it is a string, matching Sphinx's existing `TypeVar`
  stringification convention, and falls back to `repr()`.

## Assumptions and Alternatives

- I assumed the mock object should continue returning mock subclasses for
  subscript access rather than treating generic parameterization as a no-op.
  That preserves the existing behavior for string subscripts and keeps the fix
  targeted to the failing type conversion.
- I considered changing subscript display names to bracket notation such as
  `MockedClass[T]`, but rejected it because the existing mock code uses dotted
  display names for all generated subclasses and the issue only requires
  avoiding the crash.
- I did not run tests or project code, per the task instructions.
