# Baseline notes — pytest-dev__pytest-10356

## Issue

> Consider MRO when obtaining marks for classes

When pytest markers are applied to two base classes (e.g. `@pytest.mark.foo class Foo`
and `@pytest.mark.bar class Bar`), a class that inherits from both
(`class TestDings(Foo, Bar)`) loses the markers of one of the base classes. In
practice only `foo` survives — `bar` is silently dropped. Tests defined on (or
inherited into) such a multiple-inheritance class therefore see only a subset of the
marks the user declared on the ancestors.

## Root cause

Marks are stored on objects in the `pytestmark` attribute and read back through
`get_unpacked_marks()` in `src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj):
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

For a *class*, `getattr(cls, "pytestmark", [])` is resolved through Python's normal
attribute lookup, which follows the MRO and returns the **first** `pytestmark`
attribute it finds — it does *not* merge the `pytestmark` lists defined on the
different classes in the MRO. For `class TestDings(Foo, Bar)` the MRO is
`[TestDings, Foo, Bar, Base, object]`; `TestDings` has no `pytestmark` of its own, so
the lookup stops at `Foo.pytestmark == [foo]`, and `Bar.pytestmark == [bar]` is never
seen. Hence `bar` is lost.

The reason single inheritance *appeared* to work is a side effect of `store_mark()`:
when a subclass was decorated it copied the inherited marks into the subclass's own
`pytestmark` list at decoration time (`[*get_unpacked_marks(obj), mark]`). That copy
only captures whatever single MRO branch `getattr` happened to resolve, so it both
masked the bug for the common case and made a naive "walk the MRO and concatenate"
fix produce duplicate marks.

## Fix

File changed: `src/_pytest/mark/structures.py`

### 1. `get_unpacked_marks()` — walk the MRO for classes

When `obj` is a class, collect `pytestmark` from **every** class in the MRO instead of
relying on `getattr`'s first-match resolution. Each class's marks are read directly
from its own `__dict__` (`cls.__dict__.get("pytestmark", [])`), so only the marks
*directly applied to that class* are picked up — inherited attributes are not
double-counted. The MRO is iterated in `reversed` order (base classes first) so that,
for the common single-inheritance / direct-decoration case, the resulting order is
identical to the previous behaviour (base marks first, then the subclass's own marks
in decoration order). Non-class objects (functions, modules) keep the original
`getattr` behaviour, since they have no MRO.

A new keyword-only parameter `consider_mro: bool = True` lets callers request only the
marks applied directly to the object (`consider_mro=False`). The function now returns
a concrete `list` (previously a generator), which all callers already tolerate
(`.extend(...)`, `[*...]`).

### 2. `store_mark()` — store only directly-applied marks

`store_mark()` now calls `get_unpacked_marks(obj, consider_mro=False)` so that, when a
class is decorated, it records only the marks already on that class itself and does
**not** fold in inherited marks. This is the essential companion change: because
`get_unpacked_marks()` now reconstructs the full set by walking the MRO at read time,
storing inherited marks again at decoration time would produce duplicates (e.g. a mark
defined on a base would appear once from the base and once from the copied-down
subclass list). Keeping each class's `__dict__["pytestmark"]` limited to its own marks
keeps the diamond/inheritance cases duplicate-free.

### Worked examples (after the fix)

- Original report: `class TestDings(Foo, Bar)` → marks `[bar, foo]` (both present;
  base-first order from reversed MRO).
- Diamond: `@mark.a class Base`, `class A(Base)`, `class B(Base)`,
  `class C(A, B)` → `get_unpacked_marks(C) == [a]` (single copy, no duplication,
  because only `Base.__dict__` holds the mark).
- Single inheritance: `@mark.foo class Foo`, `@mark.bar class Bar(Foo)` →
  `[foo, bar]`, matching the pre-fix ordering for this case.
- Stacked decorators on one class still accumulate correctly because
  `consider_mro=False` reads the growing `__dict__["pytestmark"]` between decorators.

## Why this is sufficient (no other call sites changed)

- `Class`/`Module` collector nodes obtain their marks via the `PyobjMixin.obj`
  property (`python.py:314`), which calls `get_unpacked_marks(self.obj)`. For a
  `Class` node `self.obj` is the test class, so it now receives the MRO-merged marks.
- `Function` nodes (`python.py:1717`) call `get_unpacked_marks(self.obj)` on the test
  *function* (not a class); the non-class branch is unchanged. Class-level marks reach
  the function through the existing node-chain traversal in
  `nodes.Node.iter_markers_with_node()` (which walks `Module → Class → Function`), so
  no change is needed there.
- `terminal.py` only does a string-key membership test (`"pytestmark" not in
  keywords`) and `config/__init__.py` reads `pytestmark` off a hook *method*; neither
  involves class MRO, so both are unaffected.
- `python.py:437` already independently walks `obj.__mro__` to collect test methods —
  confirming the fix is consistent with how pytest already treats class inheritance
  during collection.

## Assumptions and alternatives considered

- **Assumption: marks should be merged across the full MRO, not name-deduplicated.**
  The issue's reporter suggested possibly "deduplicating marker names by MRO", but the
  maintainers' position in the thread ("the marks have to transfer with the mro") and
  pytest's semantics (marks like `parametrize`/`usefixtures` legitimately repeat and
  carry distinct args/kwargs) mean marks must not be collapsed by name. The fix
  therefore merges all marks and only avoids the *structural* duplication caused by
  inherited `pytestmark` lists (handled via reading each class's own `__dict__`).

- **Rejected: store marks under per-name attributes (`pytestmark_foo`, …) to lean on
  normal attribute inheritance.** Raised in the hints and dismissed there because it
  breaks down for same-name marks in diamond structures and "doesn't buy anything that
  isn't already solved". It would also be a far larger, riskier change.

- **Rejected: walking the MRO with `getattr`/concatenation while leaving `store_mark`
  unchanged.** This reintroduces duplicates, because `store_mark` had already copied
  inherited marks into each decorated subclass. Coordinating both functions
  (read via MRO + `__dict__`, store only own marks) is what keeps results
  duplicate-free.

- **Behavioural note (accepted, pre-existing maintainer guidance):** classes that
  manually concatenate a base's marks, e.g.
  `pytestmark = Base.pytestmark + [mark.x]`, can now see a duplicated base mark, since
  the base mark exists both in `Base.__dict__` and in the manually-built subclass list.
  The maintainers explicitly flagged this fix as a potential breaking change for 7.x;
  this rare manual-concatenation pattern is the accepted trade-off and is not something
  the fix tries to special-case.
