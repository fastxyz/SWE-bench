# Baseline notes — pytest-dev__pytest-10356

## Issue
"Consider MRO when obtaining marks for classes."

When markers are applied to two (or more) base classes and a test class inherits
from all of them via multiple inheritance, only the markers of *one* base class
survive. For example:

```python
@pytest.mark.foo
class Foo: ...

@pytest.mark.bar
class Bar: ...

class TestDings(Foo, Bar):
    def test_dings(self): ...   # only gets `foo`, `bar` is lost
```

The expectation is that `test_dings` carries **both** `foo` and `bar`.

## Root cause
Marks are stored on a class in the `pytestmark` attribute. Collection reads them
through `get_unpacked_marks(obj)` in `src/_pytest/mark/structures.py`:

```python
def get_unpacked_marks(obj: object) -> Iterable[Mark]:
    mark_list = getattr(obj, "pytestmark", [])
    ...
```

`getattr(cls, "pytestmark")` uses ordinary Python attribute lookup, which returns
the **first** `pytestmark` found while walking the MRO. For `TestDings(Foo, Bar)`,
`TestDings` defines no `pytestmark` of its own, so lookup stops at `Foo.pytestmark`
and `Bar`'s marks are never seen. Marks from sibling base classes are silently
dropped — single-inheritance chains happened to work only because each subclass's
`pytestmark` was eagerly rebuilt to *include* the parent's marks (see below), but
that mechanism cannot capture two independent base classes at once.

## Changes

### `src/_pytest/mark/structures.py` — `get_unpacked_marks`
Rewrote it so that when `obj` is a class it collects the `pytestmark` stored
**directly** on every class in the MRO (`reversed(obj.__mro__)`, i.e. most-base
first, matching the pre-existing ordering for single inheritance), instead of
relying on a single `getattr`. Non-class objects (functions, modules) keep the
old `getattr(obj, "pytestmark", [])` behaviour. A new keyword-only
`consider_mro: bool = True` parameter lets callers ask for only the directly
stored marks. The return type is now a concrete `List[Mark]` (callers only
`extend`/splat it, so this is compatible).

Reading `x.__dict__.get("pytestmark", [])` per class — rather than `getattr` —
is essential: it returns each class's *own* marks and avoids re-counting marks
that a base class also exposes through inheritance.

### `src/_pytest/mark/structures.py` — `store_mark`
Changed the merge call from `get_unpacked_marks(obj)` to
`get_unpacked_marks(obj, consider_mro=False)`.

Previously `store_mark` rebuilt `obj.pytestmark` as `[*all_inherited_marks, mark]`,
copying inherited marks into the subclass's own attribute. Combined with the new
MRO-walking reader that would double-count every inherited mark (the mark would
appear both in the base class's `__dict__` and, copied, in the subclass's
`__dict__`). With `consider_mro=False`, each class now stores only the marks
applied *directly* to it, and `get_unpacked_marks` reconstructs the full set by
walking the MRO. This keeps the stored data duplicate-free, so no separate
de-duplication pass is needed.

## Why this is correct / minimal
- Single-inheritance ordering is unchanged: for `Child(Base)` the result is still
  `[base_mark, child_mark]` (base first), because `reversed(__mro__)` lists the
  base before the derived class — identical to what `store_mark`'s old copying
  produced.
- Diamond inheritance does not duplicate marks: a shared base appears exactly
  once in the MRO, and since marks are no longer copied into subclasses, each mark
  is collected exactly once.
- Multiple inheritance now merges marks from all bases (the actual fix).
- Other readers of `pytestmark` are unaffected: `config/__init__.py` calls
  `getattr(method, ...)` on functions (non-class → unchanged path) and
  `terminal.py` only checks keyword membership. `python.py` reads marks solely via
  `get_unpacked_marks`; test methods inherited through the MRO are still handled by
  the function object itself (functions are not types, so the `getattr` branch
  runs), and class-level marks reach functions through the node parent chain, so
  there is no double counting.

## Assumptions / alternatives considered
- **Identifying classes via `isinstance(obj, type)`**: test classes built with a
  custom metaclass (as in the issue's workaround) are still instances of `type`,
  so they take the MRO path correctly. The metaclass workaround simply becomes
  unnecessary after this fix.
- **Explicit de-duplication in `get_unpacked_marks`** (e.g. by identity): rejected
  as unnecessary once `store_mark` uses `consider_mro=False`, because no mark is
  stored on more than one class in the MRO under normal decorator/attribute usage.
  Value-based de-duplication was explicitly rejected because it would collapse
  intentional repeated marks such as `@pytest.mark.foo` applied twice.
- **Storing marks under per-name attributes** (`pytestmark_foo`, ...), as floated
  in the issue thread: rejected — it complicates same-name marks from diamonds and
  is a far larger, riskier change than walking the MRO.
- **Behavioural note**: manually assigning `pytestmark = [...]` on a subclass no
  longer *shadows* a base class's `pytestmark`; the two are merged. This is the
  intended outcome per the issue ("attempt to merge marker values ... by MRO").
