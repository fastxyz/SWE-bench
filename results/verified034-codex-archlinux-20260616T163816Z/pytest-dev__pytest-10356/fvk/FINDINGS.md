# FVK Findings

Status: constructed, not machine-checked.

## F1: V1 fixes the reported missing-base-mark bug

Evidence: E1, E2, E3, E5; PO1.

Input shape:

```python
@pytest.mark.foo
class Foo:
    pass

@pytest.mark.bar
class Bar:
    pass

class TestDings(Foo, Bar):
    def test_dings(self):
        pass
```

Pre-fix observed behavior: class mark lookup used normal `getattr`, so
`TestDings.pytestmark` resolved to `Foo.pytestmark` and omitted `Bar.pytestmark`.

Expected behavior: `test_dings` has both `foo` and `bar`.

V1 behavior: `get_unpacked_marks(TestDings)` walks the class MRO directly and
reads each class's own `pytestmark`, so both `Foo` and `Bar` contribute marks.

Classification: code bug fixed by V1.

## F2: `store_mark(..., consider_mro=False)` is necessary

Evidence: E4, E6; PO2, PO3.

Input shape:

```python
@pytest.mark.a
class Base:
    pass

@pytest.mark.b
class Sub(Base):
    pass
```

Risk if omitted: if `store_mark` appended to all MRO-derived marks, `Sub` would
store inherited `Base` marks directly. Later MRO lookup would see the same base
mark through both `Base` and `Sub`, duplicating it.

Expected behavior: `Sub` owns only `b`; collection recovers `a` from `Base`.

V1 behavior: `store_mark` passes `consider_mro=False`, so it appends only to the
class's direct mark list.

Classification: proof-derived confirmation of a required V1 design point.

## F3: Class-MRO order remains under-specified by the issue

Evidence: E2 requires both names; E3 says to walk MRO; E7 documents closest-first
iteration for module/class/function levels but does not explicitly define sibling
base ordering.

Concrete ambiguity:

- Python MRO order for `TestDings(Foo, Bar)` suggests `foo` before `bar`.
- V1 preserves the existing base-before-subclass style by flattening
  `reversed(__mro__)`, which yields `bar` before `foo` for sibling bases.

Expected behavior for the reported bug is membership, not list order. V1 is
therefore sufficient for PO1, but order-sensitive plugins using duplicate mark
names across a multiple-inheritance hierarchy could observe this policy.

Classification: underspecified intent / residual risk, not a V1-blocking bug for
the reported issue.

UltimatePowers question: Should inherited class marks be yielded in Python MRO
order, reverse-MRO order, or only guarantee set-like completeness?

## F4: Arbitrary metaclass `pytestmark` descriptors are outside the proof domain

Evidence: the problem shows a metaclass property as a workaround, while E3/E4
identify explicit MRO walking as the desired pytest behavior.

Concrete shape:

```python
class Meta(type):
    @property
    def pytestmark(cls):
        return [pytest.mark.dynamic]

class Test(metaclass=Meta):
    def test_dynamic(self):
        pass
```

V1 reads direct class `__dict__` entries to avoid normal MRO shadowing. That is
the mechanism that fixes the bug, but it does not generally model arbitrary
metaclass descriptors as direct class marks.

Expected behavior is not established by public pytest marker API docs. The issue
uses the descriptor as a workaround for missing MRO merging, not as the target
behavior to preserve.

Classification: compatibility risk outside the proved domain. No source change
is justified without a public requirement for descriptor-based class marks.

## F5: No source edit required after FVK audit

Evidence: PO1 through PO5 discharge the required completeness, storage, and frame
conditions. PO6 records order ambiguity without using it to prove success.

Decision: V1 stands unchanged. The code fix is targeted to the reported bug and
does not require a broader order-policy or descriptor-policy change.
