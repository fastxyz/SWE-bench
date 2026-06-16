# FVK Specification: pytest class mark MRO lookup

Status: constructed, not machine-checked.

## Target

Source under audit:

- `repo/src/_pytest/mark/structures.py`
  - `get_unpacked_marks(obj, *, consider_mro=True)`
  - `store_mark(obj, mark)`

The observable behavior under audit is marker visibility through pytest's public
node marker APIs after collection, especially `Node.iter_markers()` and
`Node.get_closest_marker()`.

## Intent spec

1. A test class derived from multiple marked base classes must inherit marks from
   all classes in its MRO, not only the first base whose `pytestmark` attribute
   normal Python lookup finds.
2. Existing mark inheritance through single inheritance remains supported.
3. A mark applied to a subclass must not mutate a base class or leak to sibling
   subclasses.
4. Existing non-class behavior of `get_unpacked_marks` remains unchanged.
5. Invalid `pytestmark` contents continue to be rejected by
   `normalize_mark_list`.

The issue requires completeness of inherited class marks. It does not give an
order-sensitive assertion for sibling base classes. Order is therefore modeled
as a frame/compatibility concern, not as the correctness criterion for the bug.

## Public evidence ledger

| ID | Source | Evidence | Obligation | Status |
| --- | --- | --- | --- | --- |
| E1 | problem | "When using pytest markers in two baseclasses `Foo` and `Bar`, inheriting from both of those baseclasses will lose the markers of one of those classes." | Include marks from both marked bases. | Encoded in PO1. |
| E2 | problem | "I'd expect `foo` and `bar` to be markers for `test_dings`" | The derived test item has both marker names. | Encoded in PO1. |
| E3 | public hint | "pytest should walk the mro of a class to get all markers" | Class mark lookup must explicitly inspect the class MRO. | Encoded in PO1. |
| E4 | public hint | "The marks have to transfer with the mro, its a well used feature" | Preserve inherited mark transfer. | Encoded in PO1 and PO3. |
| E5 | public discussion | "test_d should be `[Mark(name=\"mark1\", ...), Mark(name=\"mark4\", ...)]`? Correct" | Newly defined tests in a derived class inherit marks from all marked bases. | Encoded in PO1. |
| E6 | public test/source | Existing tests assert subclass marks do not propagate to base or sibling classes. | Storing a new class decorator mark must use direct marks only. | Encoded in PO2 and PO3. |
| E7 | docs | `iter_markers` yields markers closest to the function first in documented module/class/function examples. | General marker APIs have an order concept. Class-sibling MRO order remains under-specified by the issue. | Recorded as Finding F3. |
| E8 | implementation | Pre-fix `getattr(obj, "pytestmark", [])` stops at the first MRO hit. | This is the root cause to remove for class lookup. | Encoded in PO1. |

## Domain and abstractions

The core proof models standard Python class objects with finite `__mro__`
tuples. Each class may directly define `pytestmark` in its `__dict__` as either
a list of marks/decorators or a single mark/decorator. The model abstracts
`Mark` and `MarkDecorator` to marker names after `normalize_mark_list` succeeds.

Non-class objects are modeled by their existing `getattr(obj, "pytestmark", [])`
path. Invalid mark contents are not normalized in the proof; the proof obligation
is that they still flow into the unchanged `normalize_mark_list` check.

Arbitrary metaclass descriptors for `pytestmark` are outside the proved domain.
The issue uses such a descriptor as a workaround, not as the target public API.
This residual compatibility point is recorded in `fvk/FINDINGS.md`.

## Formal claims

The formal core is emitted in:

- `fvk/mini-python-marks.k`
- `fvk/mark-mro-spec.k`

Claim summary:

- `CLAIM-MRO-COMPLETE`: for class `TestDings(Foo, Bar)` with direct marks
  `Foo -> foo` and `Bar -> bar`, `get_unpacked_marks(TestDings)` returns a list
  whose marker-name set is exactly `{foo, bar}`.
- `CLAIM-OWN-ONLY-STORE`: applying `store_mark(Sub, submark)` when `Base` owns
  `basemark` stores only `submark` directly on `Sub`; inherited marks are
  recovered later by MRO lookup.
- `CLAIM-NONCLASS-FRAME`: for non-class objects, the observed mark list is the
  same list obtained by the existing `getattr` path.
- `CLAIM-INVALID-FRAME`: invalid entries are still passed to
  `normalize_mark_list`, preserving the existing `TypeError` behavior.

The proof is partial correctness over marker lookup and storage behavior. It
does not prove collection termination or machine-check the K artifacts.
