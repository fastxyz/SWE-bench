# Baseline notes — pytest-dev__pytest-10356

## Issue
"Consider MRO when obtaining marks for classes."

When pytest markers are applied to two (or more) base classes, e.g.

```python
@pytest.mark.foo
class Foo(Base): ...

@pytest.mark.bar
class Bar(Base): ...

class TestDings(Foo, Bar):
    def test_dings(self): ...
```

`test_dings` only ends up with **one** of the marks (`foo`), silently dropping the
mark(s) from the other base class(es). The expectation is that a class that
inherits from multiple marked base classes should collect the marks from *all* of
them, following the class's MRO.

## Root cause
Marks declared with `@pytest.mark.<name>` on a class are stored in a single list
attribute named `pytestmark` on that class (via `store_mark`). Marks were later
read back by `get_unpacked_marks` in `src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj: object) -> Iterable[Mark]:
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

`getattr(cls, "pytestmark")` resolves the attribute using normal Python attribute
lookup, which returns the `pytestmark` defined on the **first** class in the MRO
that defines it. For `TestDings(Foo, Bar)`, `TestDings` does not define its own
`pytestmark`, so the lookup finds `Foo.pytestmark` (`[foo]`) and never sees
`Bar.pytestmark` (`[bar]`). Because each class stores its marks in one attribute,
only one base's marks survive — the others are shadowed rather than merged.

The previous design partly hid this for *single* inheritance because `store_mark`
did `obj.pytestmark = [*get_unpacked_marks(obj), mark]`, which (via `getattr`
inheritance) copied a parent's marks into the subclass's own list when a new mark
was added. That copy mechanism does not help when a subclass adds no new mark of
its own, and it cannot merge two sibling bases.

## Fix
File: `src/_pytest/mark/structures.py`

1. `get_unpacked_marks` now distinguishes classes from other objects:
   - For a class (`isinstance(obj, type)`) with `consider_mro=True` (the default),
     it walks the entire MRO in reverse order (`reversed(obj.__mro__)`, i.e. base
     classes first, most-derived last) and collects each class's **own** marks via
     `x.__dict__.get("pytestmark", [])`. Using `__dict__` (not `getattr`) reads
     only the marks defined directly on each class, so walking the whole MRO
     merges every base's marks exactly once and in a stable order.
   - For a class with `consider_mro=False`, it returns only that class's own marks.
   - For non-classes (modules, functions, instances) it keeps the previous
     `getattr(obj, "pytestmark", [])` behaviour, so module-level `pytestmark` and
     function marks are unchanged.
   - It now returns a concrete `List[Mark]` instead of a lazy generator.

2. `store_mark` now calls `get_unpacked_marks(obj, consider_mro=False)` so that
   adding a mark to a class only extends that class's *own* marks and never copies
   inherited marks into the subclass's attribute. This is what prevents
   duplication: with the MRO walk in `get_unpacked_marks`, inherited marks are
   reconstructed on read, so they must not also be baked into each subclass on
   write (otherwise a mark would appear once per descendant class). It also
   guarantees marks never leak "upward" onto a base class.

3. `normalize_mark_list` returns a `List[Mark]` (eagerly built) instead of a
   generator. This keeps the type honest now that `get_unpacked_marks` wraps it in
   `list(...)`, and makes the result safe to iterate more than once. The existing
   `TypeError` for non-`Mark` values is preserved (covered by
   `test_mark_with_wrong_marker`).

A changelog entry was added at `changelog/7792.bugfix.rst`.

### Why this preserves existing behaviour
- Single inheritance order is unchanged. For `@a class A` / `@b class B(A)`, the
  reversed-MRO walk yields `[a, b]`, matching the old result.
- `test_mark_decorator_subclass_does_not_propagate_to_base`: a mark added to a
  subclass stays in that subclass's own `__dict__`; the base never receives it.
- `test_mark_should_not_pass_to_siebling_class` (#568): siblings only see marks of
  classes actually on their MRO.
- `test_mark_decorator_baseclasses_merged`: deep single-inheritance chains still
  merge to `(a, b, c)` / `(a, b, d)`.
- `test_merging_markers_deep`: a class that assigns `pytestmark = pytest.mark.a`
  directly (a single `MarkDecorator`, not a list) is handled by the
  non-list branch (`mark_list.append(item)`) and still normalises to `[a]`.

### Diamond / duplicate handling
Because each class stores only its own marks and reads combine MRO via `__dict__`,
a diamond such as `@a class Base`, `@b class L(Base)`, `@c class R(Base)`,
`class D(L, R)` yields `[a, c, b]` (mark `a` appears once, since it only lives in
`Base.__dict__`). This addresses the maintainers' concern that naive per-name
attribute storage would mishandle diamond structures.

## Assumptions and rejected alternatives
- **Assumption:** the only in-tree consumers of `get_unpacked_marks`/
  `normalize_mark_list` are `store_mark` and two `own_markers.extend(...)` call
  sites in `src/_pytest/python.py`, plus a `[*..., *normalize_mark_list(...)]`
  unpack. All accept any iterable, so returning a list is compatible. Verified by
  grepping the whole repo.
- **Assumption:** behaviour for modules and plain functions must not change; only
  classes participate in MRO. Hence the `isinstance(obj, type)` branch. The
  `_get_legacy_hook_marks` helper in `config/__init__.py` reads
  `getattr(method, "pytestmark", [])` directly on routines (not classes) and is
  intentionally left untouched.
- **Rejected:** storing marks under per-name attributes (`pytestmark_foo`,
  `pytestmark_bar`) to lean on native inheritance. Maintainer discussion notes
  this still fails for same-name marks from diamond structures, so it buys nothing
  over an explicit MRO walk while complicating the public `pytestmark` attribute.
- **Rejected:** deduplicating marks by name during the MRO walk. The issue only
  asks for marks to be *merged* across bases; pytest already keeps distinct marks
  (including repeated same-name marks with different args) and resolves "closest"
  marks elsewhere (`get_closest_marker`). The `__dict__`-per-class approach
  already avoids the accidental duplication that the old copy-on-store path could
  produce, so no extra name-based dedup is needed.
- **Rejected:** changing the call sites in `python.py` to walk the MRO themselves.
  Centralising the logic in `get_unpacked_marks` keeps every caller correct and
  avoids divergent behaviour.
```
