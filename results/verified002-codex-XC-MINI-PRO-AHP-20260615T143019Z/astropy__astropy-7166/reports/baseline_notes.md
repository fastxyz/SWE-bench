# Baseline Notes

## Root Cause

`InheritDocstrings` only considered class members for docstring inheritance
when `inspect.isfunction(member)` returned `True`. A `property` object is a
data descriptor, not a function, so a subclass property that overrode an
inherited property without its own docstring was skipped and kept a `None`
docstring.

## Changed Files

- `repo/astropy/utils/misc.py`
  - Expanded the inheritable-member check in `InheritDocstrings` to include
    data descriptors via `inspect.isdatadescriptor`, which covers
    `property` and property subclasses.
  - Uses `inspect.getattr_static` when copying docstrings for data descriptors
    so descriptor objects can be inspected without invoking their `__get__`
    methods.
  - Updated the metaclass docstring to describe properties as supported
    members.

## Assumptions and Alternatives

- Assumed the intended behavior is to preserve the existing public-member and
  MRO rules, and only broaden the type of member eligible for inherited
  docstrings.
- Considered checking only `isinstance(member, property)`, but rejected that
  because Astropy has property subclasses such as `lazyproperty` and
  `classproperty`, and the issue hint points to the descriptor protocol rather
  than the concrete `property` type.
- Considered deprecating `InheritDocstrings`, but rejected that because the
  reported behavior still depends on the metaclass when a subclass redefines a
  member without writing a new docstring.
