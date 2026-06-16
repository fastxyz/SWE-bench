# Baseline Notes

## Root cause

Class marks were read with `getattr(obj, "pytestmark", [])`. For classes, normal
attribute lookup follows the MRO and stops at the first class that defines
`pytestmark`. In multiple inheritance, that means a class such as
`TestDings(Foo, Bar)` sees `Foo.pytestmark` and never reads `Bar.pytestmark`.
Collection then only attaches the marks from the first marked base class.

## Changed files

- `repo/src/_pytest/mark/structures.py`
  - Updated `get_unpacked_marks` so class objects can collect `pytestmark` values
    by explicitly walking `reversed(obj.__mro__)` and reading each class's own
    `__dict__`. This preserves the existing base-before-subclass ordering while
    including marks from all base classes in multiple inheritance.
  - Added a `consider_mro` option and used `consider_mro=False` in `store_mark`.
    Storing a newly applied decorator mark should append only to marks directly
    present on that class; inherited marks are now gathered during mark lookup.
    This avoids duplicating inherited marks on decorated subclasses.

## Assumptions and alternatives

- I assumed the intended behavior is for every test collected under a derived
  class to inherit class-level marks from all classes in its MRO, including
  multiple base classes.
- I preserved the existing behavior that a non-list `pytestmark` value is treated
  as a single mark object, rather than broadening this change to accept other
  collection types.
- I considered only changing collection of `Class` nodes, but rejected that
  because `get_unpacked_marks` is the central helper already used for marker
  lookup and storage.
- I considered de-duplicating marks while leaving inherited marks copied into
  subclass `pytestmark` attributes, but rejected that because repeated marks can
  be meaningful and object/name-based de-duplication would be a broader semantic
  change.
- I did not add or modify tests, and I did not run tests or project code, per the
  task constraints.
