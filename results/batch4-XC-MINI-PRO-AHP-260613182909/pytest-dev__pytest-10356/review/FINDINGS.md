# Code review — V1 fix for pytest-dev__pytest-10356

Scope of V1: `src/_pytest/mark/structures.py`
- `get_unpacked_marks` rewritten to walk the full MRO for classes, reading each
  class's *own* `pytestmark` from `cls.__dict__`; added keyword-only
  `consider_mro: bool = True`; return type tightened to `List[Mark]`.
- `store_mark` now calls `get_unpacked_marks(obj, consider_mro=False)` so only
  directly-applied marks are persisted on the object.
- Added `changelog/7792.bugfix.rst`.

Review method: static reasoning only (no execution available). Each finding
states the scenario, the traced behavior of V1, and a verdict.

---

## A. Correctness against the issue as described

### F1 — Core bug is fixed (multiple inheritance no longer drops marks). PASS
Issue example: `@a class A`, `@b class B`, `@c class C(A, B)`.
- `store_mark(A,a)` → `A.__dict__["pytestmark"] == [a]`; likewise `B` → `[b]`;
  `store_mark(C,c)` reads only `C`'s own dict (empty) → `C.__dict__["pytestmark"] == [c]`.
- `get_unpacked_marks(C)` iterates `reversed(C.__mro__)` =
  `[object, B, A, C]` → `[b, a, c]`.
All three marks present; previously `b` was silently lost. The reported
`TestDings(Foo, Bar)` case likewise yields both `foo` and `bar`. Matches the
maintainers' stated goal ("marks have to transfer with the mro").

### F2 — End-to-end keyword/`-m` selection works. PASS
`Class` node (`python.py:314-317`) extends `own_markers` from
`get_unpacked_marks(self.obj)` and updates `self.keywords` with every mark name.
With all base marks merged, `-m foo` and `-m bar` both now match a test in
`TestDings(Foo, Bar)`, which is the user-visible objective.

### F2b — The issue's detailed `Test3(Test1, Test2)` example yields the
maintainer-endorsed result. PASS
`@mark1 class Test1`, `@mark4 class Test2`, `class Test3(Test1, Test2)`.
`get_unpacked_marks(Test3)` over reversed MRO `[object, Test2, Test1, Test3]`
gives `Test3.own_markers == [mark4, mark1]`. A test method resolves markers via
`Node.iter_markers_with_node`, which walks `reversed(listchain())` and includes
the `Class(Test3)` node's `own_markers`. Therefore `test_d` (no own marks)
sees `{mark1, mark4}` — exactly the correction RonnyPfannschmidt gave in the
thread (the original poster's "empty" expectation was explicitly overruled).
Methods defined on the bases are collected under `Test3` (per the MRO walk in
`PyCollector.collect`, see F17), so e.g. `test_a` sees its own `mark2` plus the
class-level `{mark1, mark4}` — the consistent outcome of "Test3 as a whole
carries all base-class marks." This confirms the fix at the level the issue
discussed in most detail.

### F3 — Single inheritance order is byte-for-byte preserved. PASS (no regression)
For `@a class A`, `@b class B(A)`, `@c class C(B)`:
- V0 (old): `store_mark` appended onto the inherited list, producing
  `get_unpacked_marks(C) == [a, b, c]`.
- V1: own-only storage + `reversed(mro)` walk
  (`[object, A, B, C]`) reproduces exactly `[a, b, c]`.
Choosing `reversed(obj.__mro__)` (base-first) is what preserves the legacy
ordering; forward MRO order would have inverted it and risked regressing
`get_closest_marker` precedence for existing single-inheritance suites.

---

## B. Edge cases and boundary conditions

### F4 — Diamond inheritance does not duplicate the shared base's marks. PASS
`@base Base`, `@foo Foo(Base)`, `@bar Bar(Base)`, `class D(Foo, Bar)`:
MRO `[D, Foo, Bar, Base, object]` — every class appears exactly once. Because
V1 reads each class's *own* `__dict__` (not `getattr`, which would re-resolve
inheritance per class), `Base`'s mark is collected exactly once →
`[base, bar, foo]`. This is the central reason `__dict__` is used instead of
`getattr` per MRO entry.

### F5 — Per-class non-list `pytestmark` is handled. PASS
A base with `pytestmark = pytest.mark.foo` (a single `MarkDecorator`, not a
list) is handled by the per-item `isinstance(item, list)` check in the class
branch (append vs extend). The non-class branch retains the original
single-value wrapping. `normalize_mark_list` then unwraps decorators.

### F6 — Class body `pytestmark` + decorator combine without duplication. PASS
`@b class B: pytestmark = [a]` → class body sets `[a_dec]`, then `store_mark`
with `consider_mro=False` reads `B`'s own dict → `B.__dict__["pytestmark"] ==
[Mark(a), b]`; collection yields `[Mark(a), b]`. No double counting.

### F7 — Sibling base ordering is "second-base-first" ([b, a, c]). ACCEPTABLE
In `C(A, B)`, reversed MRO places `B` before `A`, so `B`'s marks precede `A`'s.
This is a brand-new case with no prior behavior to preserve, the issue does not
specify sibling precedence, and all marks are present. Cannot satisfy both
"base-before-derived" and "first-base-before-second-base" with a plain MRO
reversal; preserving F3 (single-inheritance order) takes priority. No action.

### F8 — Empty / default `pytestmark`. PASS
`cls.__dict__.get("pytestmark", [])` returns `[]` for classes without the
attribute (e.g. `object`, intermediate bases), which `extend`s nothing.

---

## C. Error handling

### F9 — Malformed `pytestmark` still raises the same `TypeError`. PASS
A non-Mark/non-decorator value (e.g. a string) flows into
`normalize_mark_list`, which raises `TypeError("got ... instead of Mark")` as
before. V1 now forces evaluation eagerly via `list(...)`, so the error surfaces
at call time rather than on first iteration — a strictly clearer failure point;
both old call sites (`extend`, `[*...]`) iterated immediately anyway.

### F10 — No new exceptions introduced. PASS
`isinstance(obj, type)`, `reversed(tuple)`, and `mappingproxy.get(...)` are all
total operations for any class object; every class has `__mro__` and `__dict__`
in Python 3.

---

## D. Interactions and possible regressions

### F11 — Return type changed from lazy generator to `List[Mark]`. PASS
Old `get_unpacked_marks` returned the `normalize_mark_list` generator; V1
returns a concrete list. All three callers (`store_mark` unpack,
`python.py:314` and `:1717` `extend`) consume it eagerly and never depend on
laziness or generator identity. List is also re-iterable and matches the new,
more accurate `List[Mark]` annotation.

### F12 — `store_mark` no longer copies inherited marks into the subclass dict.
ACCEPTABLE / REQUIRED.
Old `B.__dict__["pytestmark"]` for `@b class B(A)` was `[a, b]`; V1 makes it
`[b]`. This is *required* to avoid double counting once reads walk the MRO
(without it, `a` would appear from both `B`'s copied dict and `A`'s own dict).
Direct user access to `Subclass.pytestmark` (an undocumented, non-public detail)
now returns own-only marks; the supported APIs (`iter_markers`,
`get_closest_marker`, keywords) still see the full inherited set via the MRO
walk.

### F13 — Subclass can no longer "clear"/"override" inherited marks via
`pytestmark = []` (or by re-declaring the attribute). INTENDED BEHAVIOR CHANGE.
With MRO merging, `class B(A): pytestmark = []` still inherits `A`'s `a`.
Likewise re-declaring `pytestmark = [...]` now merges rather than shadows. This
is the direct, intended consequence of "marks transfer with the MRO" per the
issue thread; it is a potential breaking change suitable for a feature release
(7.x), consistent with the maintainers' notes. Documented in control_notes.

### F14 — Metaclass `pytestmark` property workaround degrades. ACCEPTABLE.
The issue's `BaseMeta` workaround stores marks in `_pytestmark` and exposes
`pytestmark` via a metaclass property. V1 reads `cls.__dict__["pytestmark"]`,
bypassing the property, so that specific workaround stops contributing marks.
Acceptable because the fix makes the workaround unnecessary (real marks applied
via `@pytest.mark.*` / class-body `pytestmark` are found through the MRO walk).
No supported feature regresses.

### F15 — Modules and functions are unaffected. PASS
`Module` objects and function/method objects are not `type` instances, so they
take the unchanged `else` branch (`getattr` + single-value wrap). The
`Function` node call (`python.py:1717`) and module-level `pytestmark` behave
exactly as before. `_get_legacy_hook_marks` (`config/__init__.py:354`) reads
`pytestmark` only from routines (methods), unaffected.

### F16 — `add_marker` (runtime) path unaffected. PASS
`nodes.Node.add_marker` mutates `own_markers`/`keywords` directly and never
calls `get_unpacked_marks`; no interaction.

---

## E. Consistency with conventions and API contracts

### F17 — Implementation mirrors existing MRO-walking idiom. PASS
`PyCollector.collect()` (`python.py:434-438`) already does
`if isinstance(self.obj, type): for basecls in self.obj.__mro__:
dicts.append(basecls.__dict__)` to gather test methods from all bases. V1's
mark collection uses the identical `isinstance(obj, type)` + per-class
`__dict__` pattern, so the fix is idiomatic for this codebase. It also explains
why base-class *methods* are collected, making base-class *marks* propagation
the consistent counterpart.

### F18 — Typing / mypy. PASS
`List` and `Union` are already imported; `Iterable` remains used elsewhere, so
no import churn. `mark_list = []` resolves its partial type via the subsequent
`extend`/`append`; the non-class branch yields `List`/`Any`; the join feeds
`normalize_mark_list(Iterable[...])` and `list(...)` returns `List[Mark]`,
matching the annotation. `Union[object, type]` is intentionally explicit about
the dual handling (technically equivalent to `object`).

### F19 — `consider_mro` default is correct. PASS
Default `True` ensures the one class call site (`python.py:314`) gets MRO
merging — the fix — while `store_mark` opts out with `False`. The function/
module call sites are non-types and unaffected by the flag.

### F20 — Changelog. PASS
`changelog/7792.bugfix.rst` exists, names the originating issue number, is
written in present tense ending with a period, matching `changelog/README.rst`
conventions and sibling files.

---

## Overall verdict

No correctness defects found. Every behavior change beyond the core fix
(F12–F14) is either required to make the fix sound or an explicitly intended
consequence of MRO-based marker inheritance as described in the issue and
endorsed by maintainers. The implementation is idiomatic (F17) and type-clean
(F18). **V1 stands unchanged.**
