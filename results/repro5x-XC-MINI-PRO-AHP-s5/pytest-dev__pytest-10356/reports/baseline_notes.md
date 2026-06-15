# Baseline notes: pytest-dev__pytest-10356

## Issue

When pytest markers are applied to two base classes (e.g. `@pytest.mark.foo` on
`Foo` and `@pytest.mark.bar` on `Bar`), a class that inherits from *both*
(`class TestDings(Foo, Bar)`) only keeps the marks of *one* base class. The
expectation is that both `foo` and `bar` are present on the inherited tests.

The maintainers' agreed resolution (per the public hints) is that pytest should
"walk the MRO of a class to get all markers" and merge them, deduplicating by
MRO.

## Root cause

Marks are stored on a class in a single list attribute, `pytestmark`. Marks were
read back via `get_unpacked_marks` in `src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj: object) -> Iterable[Mark]:
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

`getattr(cls, "pytestmark", [])` uses ordinary Python attribute lookup, which
returns the `pytestmark` list of the **first** class in the MRO that defines it,
rather than merging the `pytestmark` lists of every class in the MRO. For
`TestDings(Foo, Bar)` the MRO is `[TestDings, Foo, Bar, Base, object]`; `Foo` is
the first class carrying a `pytestmark`, so only `foo` was returned and `bar` was
silently lost.

(Note this also affected the less common single-inheritance case where a subclass
explicitly re-assigns `pytestmark = [...]`, since that assignment shadowed the
base class list entirely.)

## Changes

### 1. `src/_pytest/mark/structures.py` — `get_unpacked_marks`

Rewrote the function so that, when `obj` is a class, it walks the full MRO
(`reversed(obj.__mro__)`) and concatenates each class's *own* `pytestmark`
(read from `cls.__dict__`, i.e. not inherited) instead of relying on a single
`getattr`. Non-class objects (modules, functions/methods) keep the previous
behaviour via the `else` branch.

A keyword-only `consider_mro: bool = True` parameter was added. With
`consider_mro=False` the function returns only the marks declared directly on the
class (from its `__dict__`), which is needed by `store_mark` (see below). The
return type is now a concrete `list` (it was an iterator/generator before); all
callers either `extend()` it or unpack it with `[*...]`, so this is compatible.

Reading from `cls.__dict__` per MRO entry rather than `getattr` is essential:
each class appears exactly once in the MRO and contributes only the marks applied
directly to it, so every mark is collected exactly once and diamond inheritance
does not produce duplicates.

Ordering is preserved/intuitive: `reversed(__mro__)` puts the least-derived
classes first and the most-derived class last, matching the pre-existing
single-inheritance order (base-class marks before subclass marks), and giving
higher-priority (earlier-in-MRO) classes the later position in the list.

### 2. `src/_pytest/mark/structures.py` — `store_mark`

Changed the read from `get_unpacked_marks(obj)` to
`get_unpacked_marks(obj, consider_mro=False)`.

This is the companion change that keeps the MRO walk correct. `store_mark` is
called by the `@pytest.mark.X` decorator/declaration machinery and writes
`obj.pytestmark = [...]`, which lands in `obj.__dict__["pytestmark"]`. If it kept
reading the MRO-merged list, a subclass decorated with a new mark would copy its
inherited marks into its own `__dict__`; the new MRO walk would then read those
inherited marks again from the parent, producing duplicates. By storing only the
class's own marks plus the new one, each class's `__dict__` holds exactly the
marks declared on it, and the MRO walk in `get_unpacked_marks` reassembles the
full set without duplication.

### 3. `changelog/7792.bugfix.rst`

Added a changelog entry, following the project's PR convention referenced in
`benchmark/PROBLEM.md` (original issue is #7792).

## Verification reasoning (no execution available)

For the reproducer `class TestDings(Foo, Bar)`:
- `Foo.__dict__["pytestmark"] == [foo]`, `Bar.__dict__["pytestmark"] == [bar]`.
- `get_unpacked_marks(TestDings)` walks `reversed(MRO)` =
  `[object, Base, Bar, Foo, TestDings]` and yields `[bar, foo]` — both marks
  present. `Class.obj` then extends `own_markers` with these, so `test_dings`
  carries both marks.

Single inheritance (`@pytest.mark.bar class Bar(Foo)` where `Foo` has `foo`)
still yields `[foo, bar]`, identical ordering to before the fix.

## Alternatives considered and rejected

- **Storing marks as per-name attributes (`pytestmark_foo`, `pytestmark_bar`) to
  rely on normal inheritance** (suggested in the issue thread): rejected. The
  maintainers noted it doesn't solve combining same-named marks from diamond
  structures and still effectively requires MRO handling, so it buys nothing over
  the explicit MRO walk while being a larger, more invasive change.

- **Adding explicit name-based deduplication of the merged mark list**: rejected
  as unnecessary and behaviour-changing. With the `store_mark(consider_mro=False)`
  change each class's `__dict__` holds only its own marks and each class appears
  once in the MRO, so no duplicates arise from inheritance. Deduplicating by name
  would also wrongly collapse legitimately repeated marks (e.g. the same mark
  applied twice with different args).

- **Changing the callers in `python.py` instead of `get_unpacked_marks`**:
  rejected. The bug is in how marks are *read* from a class, so fixing the single
  shared accessor (`get_unpacked_marks`) addresses every caller uniformly and
  keeps the change minimal.
