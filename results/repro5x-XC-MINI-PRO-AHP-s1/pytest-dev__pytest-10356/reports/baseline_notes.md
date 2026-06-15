# Baseline notes — pytest-dev__pytest-10356

## Issue

> Consider MRO when obtaining marks for classes

When pytest markers are applied to two base classes (`Foo`, `Bar`) and a third
class inherits from both (`class TestDings(Foo, Bar)`), the marks of one of the
base classes are silently lost. The reporter's minimal reproduction:

```python
@pytest.mark.a
class A: pass

@pytest.mark.b
class B: pass

@pytest.mark.c
class C(A, B): pass

C.pytestmark  # -> [Mark(name='a'), Mark(name='c')]  --  'b' is missing!
```

The agreed-upon intended behavior (per maintainer comments in the issue): marks
must transfer with the MRO, and this should extend to multiple inheritance, so
`C` should carry `a`, `b`, and `c`.

## Root cause

Marks are stored on classes in the `pytestmark` attribute and read back by
`get_unpacked_marks()` in `src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj: object) -> Iterable[Mark]:
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

`getattr(cls, "pytestmark")` uses Python's normal attribute lookup, which walks
the MRO but stops at the **first** class that defines `pytestmark`. So for
`C(A, B)`, only `A.pytestmark` is seen and `B`'s marks are never read.

The previous design partially hid this for *single* inheritance because
`store_mark()` "copied down" the inherited marks at decoration time:
`obj.pytestmark = [*get_unpacked_marks(obj), mark]`. When a subclass was
decorated, `get_unpacked_marks` (via `getattr`) returned the parent's marks and
they were re-stored on the subclass. But this copy-down only ever followed the
single attribute that `getattr` resolved, so the *second* (and later) base in a
multiple-inheritance hierarchy was dropped. A class that inherits but is not
itself decorated never triggered the copy-down at all.

## Fix

File changed: `src/_pytest/mark/structures.py`

1. **`get_unpacked_marks`** now explicitly walks the MRO for classes:
   - For a class, it collects `cls.__dict__.get("pytestmark", [])` for every
     class in `reversed(obj.__mro__)` (base classes first, the class itself
     last — this preserves the ordering the old copy-down produced for linear
     inheritance) and concatenates them. Using `__dict__` (rather than
     `getattr`) reads only the marks declared *directly* on each class, so each
     mark in the hierarchy is gathered exactly once.
   - A new keyword-only parameter `consider_mro: bool = True` is added. When
     `False`, only the class's own `__dict__["pytestmark"]` is returned (no MRO
     walk).
   - Non-class objects (functions, modules) keep the previous `getattr`-based
     behavior, including wrapping a non-list `pytestmark` (e.g. the documented
     module-level `pytestmark = pytest.mark.webtest`) into a list.
   - Each per-class value is also allowed to be a single mark instead of a list
     (handled by the `isinstance(item, list)` check), matching the old
     non-list tolerance.

2. **`store_mark`** now calls `get_unpacked_marks(obj, consider_mro=False)`.
   This is the crucial companion change: the decorator must store only the
   marks applied *directly* to the class, and must **not** copy down inherited
   marks. Because each class's `__dict__["pytestmark"]` then holds only its own
   marks, the MRO walk in `get_unpacked_marks` gathers every mark once with no
   duplication — including diamond hierarchies, where a shared base's mark would
   otherwise have been counted multiple times.

3. **`normalize_mark_list`** was changed from a generator to return a concrete
   `List[Mark]` (and its/`get_unpacked_marks`'s return annotations updated to
   `List[Mark]`). This keeps the documented "returns a new list" contract and
   avoids returning a lazy generator built over `__mro__`. Behavior is
   otherwise identical (it still raises `TypeError` on a non-`Mark`). Its only
   other caller, `_pytest/python.py:1150`, unpacks it with `*`, which is
   unaffected.

### Why this resolves the issue

For `class C(A, B)` with `A`, `B`, `C` each decorated:
- `A.__dict__["pytestmark"] == [a]`, `B.__dict__["pytestmark"] == [b]`,
  `C.__dict__["pytestmark"] == [c]` (each stored with `consider_mro=False`).
- Collecting `C` calls `get_unpacked_marks(C)` (default `consider_mro=True`),
  which walks `reversed((C, A, B, object))` and yields `[b, a, c]` — all three
  marks present.

The original issue's `TestDings(Foo, Bar)` (undecorated subclass) likewise
yields `[bar, foo]` because the MRO walk reads `Foo` and `Bar` directly.

## Callers reviewed (no change needed)

- `src/_pytest/python.py:314` (`PyobjMixin.obj`) and `:1717`
  (`Function.__init__`) call `get_unpacked_marks(self.obj)` with the default
  `consider_mro=True`. For `Class`/`Module` nodes `self.obj` is the class/module
  (classes correctly walk the MRO); for `Function` nodes `self.obj` is a
  function and takes the non-class branch, so `consider_mro` is irrelevant.
- `src/_pytest/config/__init__.py:354` (`_get_legacy_hook_marks`) reads
  `getattr(method, "pytestmark", [])` on a plugin **hook function** for legacy
  deprecation detection; it has nothing to do with class marker inheritance.
- `src/_pytest/terminal.py` only checks the literal keyword string
  `"pytestmark"`; unrelated.

## Assumptions and rejected alternatives

- **Assumption: this is intentionally a (potentially) breaking change.** The
  issue thread states the fix should land in a major release, and the task
  metadata pins version 7.2. A subclass that re-declares `pytestmark` in its
  body will now also inherit base-class marks via the MRO (previously the
  re-declaration shadowed them). That is the explicitly desired post-fix
  behavior ("marks have to transfer with the mro").
- **Rejected: deduplicating marks by value/identity during the MRO walk.**
  Tempting as a guard against duplicates, but unnecessary once `store_mark`
  uses `consider_mro=False`: each class stores only its own marks, so the walk
  produces no duplicates even for diamonds. Adding value-based dedup would also
  wrongly merge legitimately distinct same-name marks (e.g.
  `@pytest.mark.foo(1)` vs `@pytest.mark.foo(2)`), so it was avoided.
- **Rejected: storing marks under per-name attributes (`pytestmark_foo`,
  `pytestmark_bar`) to lean on native attribute inheritance** (suggested in the
  issue). As noted in the thread, this breaks for same-name marks in diamond
  structures and buys nothing over an explicit MRO walk; it is also a far larger
  change.
- **Rejected: using `getattr` on each MRO class instead of `__dict__`.** That
  would re-read inherited attributes at every level and massively duplicate
  marks. `cls.__dict__.get(...)` reads only directly-declared marks, which is
  what the MRO walk requires.
- **Note on the metaclass workaround in the report.** The reporter's
  `pytestmark` `@property` workaround stored marks in `_pytestmark`; the fix
  uses `__dict__["pytestmark"]` and makes that workaround unnecessary. Continuing
  to support that exact property-based metaclass shim was treated as out of
  scope — the fix targets the default behavior for ordinary classes.
