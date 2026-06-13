# Baseline notes — pytest-dev__pytest-10356

## Issue

"Consider MRO when obtaining marks for classes."

When pytest markers are applied to two (or more) base classes and a test class
inherits from all of them, the markers of all but one base class are silently
lost. The reported example:

```python
@pytest.mark.a
class A: pass

@pytest.mark.b
class B: pass

@pytest.mark.c
class C(A, B): pass

# C.pytestmark == [Mark('a'), Mark('c')]   # 'b' is missing!
```

Expected: `C` should carry markers `a`, `b` and `c`. Maintainers confirmed in
the issue thread that marks must transfer along the MRO and that not doing so
for multiple inheritance is a bug.

## Root cause

Marks are stored in a single per-object attribute named `pytestmark`, and the
collection logic read it with plain attribute access:

`src/_pytest/mark/structures.py`

```python
def get_unpacked_marks(obj):
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

For a class, `getattr(obj, "pytestmark")` follows Python's normal attribute
lookup, which walks the MRO and returns the **first** `pytestmark` it finds.
With `class C(A, B)`, the lookup stops at `A.pytestmark` and never sees
`B.pytestmark`, so `B`'s marks disappear.

The problem is compounded by `store_mark`, used by the `@pytest.mark.*`
decorators:

```python
obj.pytestmark = [*get_unpacked_marks(obj), mark]
```

When `@pytest.mark.c` is applied to `C(A, B)`, `get_unpacked_marks(C)` returned
only the first inherited list (`A`'s), so `C.pytestmark` was permanently frozen
to `[<A's marks>, c]`, baking the data loss into `C`'s own attribute.

## Fix

File changed: `src/_pytest/mark/structures.py`

### 1. `get_unpacked_marks` — walk the full MRO for classes

`get_unpacked_marks` now distinguishes classes from other objects:

- If `obj` is a class (`isinstance(obj, type)`), it collects each class's
  **own** `pytestmark` (read from `cls.__dict__`, not via `getattr`) for every
  class in `reversed(obj.__mro__)`, and concatenates them. Reading from
  `__dict__` is essential: using `getattr` on each MRO entry would re-resolve
  inheritance per class and produce massive duplication.
- Otherwise (modules, functions, methods) it keeps the previous behaviour:
  read `pytestmark` via `getattr` and wrap a non-list value in a list.

A new keyword-only parameter `consider_mro: bool = True` lets callers ask for
only the directly-applied marks (used by `store_mark`, see below). The return
type was tightened from `Iterable[Mark]` to `List[Mark]` (it now always returns
a concrete list); all three call sites use it with `extend(...)`/`[*...]`, so a
list is fully compatible.

Ordering: iterating `reversed(obj.__mro__)` yields base classes before derived
classes (object → ... → C). For single inheritance this reproduces the exact
order the old `store_mark`-append behaviour produced (`[base_mark, derived_mark]`),
so existing single-inheritance expectations are preserved. Because each class
appears exactly once in an MRO and we read each class's *own* marks, diamond
hierarchies do not duplicate a shared base class's marks.

### 2. `store_mark` — store only the object's own marks

```python
obj.pytestmark = [*get_unpacked_marks(obj, consider_mro=False), mark]
```

By passing `consider_mro=False`, applying a decorator to a subclass no longer
copies inherited marks into the subclass's own `pytestmark`. Inherited marks are
instead discovered at read time by the MRO walk above. This keeps each class's
stored `pytestmark` limited to its own marks and prevents double-counting when
`get_unpacked_marks` later merges across the MRO.

### 3. Changelog

Added `changelog/7792.bugfix.rst` describing the user-visible change, following
the repository's changelog convention (issue number `7792` is the original bug).

## Why this is the right layer

Marker collection for the three relevant node kinds all routes through
`get_unpacked_marks`:

- `Module` node: object is a module (not a type) → unchanged `else` branch.
- `Class` node (`python.py` `PyobjMixin.obj`, `_ALLOW_MARKERS = True`): object is
  the class → new MRO-walking branch. This is exactly where the bug lived.
- `Function` node (`python.py:1717`): object is a function (not a type) →
  unchanged `else` branch.

So the change is surgically scoped to class marker collection and leaves module-
and function-level marker handling byte-for-byte identical.

## Worked example (post-fix)

For the issue's `class TestDings(Foo, Bar)` where `Foo` is marked `foo` and
`Bar` is marked `bar`:

- `store_mark(Foo, foo)` → `Foo.__dict__["pytestmark"] == [foo]`
- `store_mark(Bar, bar)` → `Bar.__dict__["pytestmark"] == [bar]`
- `get_unpacked_marks(TestDings)` walks `reversed(MRO)` =
  `[object, Base, Bar, Foo, TestDings]` → `[bar, foo]`

Both markers are now present.

## Assumptions and rejected alternatives

- **Merge semantics over override semantics.** A subclass that re-declares
  `pytestmark = [...]` in its body previously *overrode* the parent's marks via
  attribute shadowing; it now *merges* with them along the MRO. This is a
  deliberate, intended consequence — the issue and maintainer comments
  explicitly ask for marks to transfer with the MRO ("its a well used feature
  and its a bug that it doesn't extend to multiple inheritance"). It is a
  potential behaviour change for the unusual case of intentional override, which
  the maintainers accepted as appropriate for a major release.

- **Rejected: metaclass-based workaround.** The issue shows a `BaseMeta`
  metaclass exposing a merging `pytestmark` property. That only fixes classes
  that opt in to the metaclass and is awkward to apply generally; the bug should
  be fixed in pytest itself.

- **Rejected: storing marks as separate attributes (`pytestmark_foo`,
  `pytestmark_bar`).** Suggested in the thread to lean on native attribute
  inheritance, but as noted there it breaks for same-named marks coming from
  diamond structures and "doesn't buy anything that isn't already solved." The
  explicit MRO walk is simpler and handles diamonds correctly.

- **Rejected: deduplicating marks by name.** The issue floats deduplicating
  marker *names*. I did not implement name-based dedup: marks legitimately repeat
  (e.g. multiple `@pytest.mark.parametrize` or repeated custom marks carrying
  different args), and `iter_markers` already preserves and orders all marks. The
  MRO walk only avoids the structural duplication that would arise from visiting
  the same class twice, which cannot happen since each class occurs once in an
  MRO and we read each class's own dict.

- **Reading `cls.__dict__` rather than `getattr` per MRO entry.** Required for
  correctness: `getattr` on each base would itself resolve inheritance and
  return overlapping lists, duplicating ancestor marks. `__dict__.get` returns
  exactly the marks declared on that one class.
