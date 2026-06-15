# Baseline notes: pytest-dev__pytest-10356

## Issue summary

When pytest markers are applied to two (or more) base classes and a test class
inherits from all of them, markers from all but one of the base classes are
silently lost. For example:

```python
@pytest.mark.foo
class Foo: pass

@pytest.mark.bar
class Bar: pass

class TestDings(Foo, Bar):
    def test_dings(self): ...
```

`test_dings` only ends up with the `foo` marker; `bar` disappears. The reporter
wanted markers to be merged following the MRO, and the maintainer
(RonnyPfannschmidt) confirmed the intended behavior: "The marks have to transfer
with the mro ... it's a bug that it doesn't extend to multiple inheritance."

## Root cause

Marks are stored on a class in a single `pytestmark` list attribute, and they
were read back with:

```python
def get_unpacked_marks(obj):
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

For a class, `getattr(cls, "pytestmark", [])` resolves the attribute through
normal Python attribute lookup, which follows the MRO and returns the **first**
`pytestmark` list it finds — i.e. only the list belonging to a single class in
the hierarchy. With multiple inheritance (`TestDings(Foo, Bar)`), `Foo` is found
first and `Bar`'s `pytestmark` is never consulted, so `bar` is lost. The marks
are not merged across the MRO at all.

The companion function `store_mark` compounded this single-attribute model:

```python
def store_mark(obj, mark):
    obj.pytestmark = [*get_unpacked_marks(obj), mark]
```

At decoration time it copied any *inherited* marks (found via `getattr`/MRO) into
the subclass's own `pytestmark`. That copy is what would cause duplicates once
`get_unpacked_marks` starts walking the MRO itself.

## Changes made

### `src/_pytest/mark/structures.py`

1. **`get_unpacked_marks`** — now walks the MRO for classes.
   - Added a keyword-only parameter `consider_mro: bool = True`.
   - When `obj` is a class (`isinstance(obj, type)`) and `consider_mro` is true,
     it collects each class's *own* `pytestmark` via
     `x.__dict__.get("pytestmark", [])` for every `x` in `reversed(obj.__mro__)`
     and concatenates them. When `consider_mro` is false it reads only
     `obj.__dict__.get("pytestmark", [])` (the class's own marks).
   - For non-class objects (functions, modules) behavior is unchanged: it uses
     `getattr(obj, "pytestmark", [])`.
   - Return type tightened from `Iterable[Mark]` to a concrete `List[Mark]`
     (both existing callers already consumed it as an iterable, so this is safe).

   Reading each class's `__dict__` directly (rather than `getattr`) is the key:
   it captures the marks that physically belong to each class exactly once, so a
   shared base class in a diamond contributes its marks a single time and there
   is no duplication.

   `reversed(obj.__mro__)` is used so marks are ordered base-class-first and the
   most-derived class last. This preserves the historical ordering for single
   inheritance (base marks came before the subclass's own marks), keeping the
   change backward compatible for the common case.

2. **`store_mark`** — now calls `get_unpacked_marks(obj, consider_mro=False)` so
   that decorating a class stores only that class's own marks, never the
   inherited ones. The inherited marks are merged on read instead. Without this
   change, marks inherited at decoration time plus marks merged again on read
   would be duplicated.

### `changelog/7792.bugfix.rst`

Added a changelog entry (documentation only) describing the fix, referencing the
original issue number 7792, following the existing `*.bugfix.rst` convention.

No test files were modified.

## Why the fix is correct / unaffected callers

- `src/_pytest/python.py:314` (the `PyobjMixin.obj` property) calls
  `get_unpacked_marks(self.obj)` for collector nodes. For a `Class` node
  `self.obj` is the class, so the new MRO walk now yields marks from every base
  class; these become the class node's `own_markers`, which propagate to every
  test method collected under it via the normal node/`iter_markers` chain.
- `src/_pytest/python.py:1717` (`Function.__init__`) calls it on the test
  function object, which is not a class, so it takes the unchanged `getattr`
  branch.
- `src/_pytest/config/__init__.py:354` reads `pytestmark` directly off a
  *method* (routine), not via `get_unpacked_marks`, and is unaffected.

## Assumptions and rejected alternatives

- **Ordering: reversed MRO (chosen).** I order marks base-first / derived-last to
  match the pre-existing order produced for single inheritance. The exact order
  is not specified by the issue (which only requires that no marks be lost), but
  matching prior behavior minimizes surprise. Forward MRO order was rejected
  because it would reverse the long-standing ordering for single inheritance.

- **Storing marks as per-name attributes (`pytestmark_foo`, etc.), as floated in
  the issue thread — rejected.** The maintainers noted it "doesn't buy anything
  that isn't already solved" and complicates combining same-name marks from
  diamond structures. Walking the MRO over `__dict__` already deduplicates a
  shared base's marks naturally, so the simpler single-attribute model is kept.

- **Reading via `getattr` inside the MRO walk — rejected.** Using `getattr` per
  class would re-resolve inheritance for each class and reintroduce duplication
  in diamonds; reading each class's own `__dict__` is what gives exactly-once,
  per-class collection.

- **Metaclass `pytestmark` property workaround.** A user workaround in the issue
  defined `pytestmark` as a metaclass property storing into `_pytestmark`. After
  this fix that workaround is unnecessary; it is also no longer relied upon
  (the fix reads each class's own `__dict__['pytestmark']`). This is acceptable
  and consistent with the maintainers' direction to walk the MRO using normal
  class attributes.

- **Behavioral note (intended, per maintainer).** Every test method collected
  under a subclass now receives the merged class-level marks from the subclass's
  full MRO, not just the marks of the class where the method was defined. This
  matches RonnyPfannschmidt's confirmation that, e.g., a method inherited into
  `Test3(Test1, Test2)` gains the class-level marks of both `Test1` and `Test2`.
  This is a (documented) potentially breaking change appropriate for a feature
  release.
